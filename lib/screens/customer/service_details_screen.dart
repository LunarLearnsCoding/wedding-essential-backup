import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../models/inquiry_model.dart';
import '../../services/booking_service.dart';
import '../../services/inquiry_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final BookingService _bookingService = BookingService();
  final InquiryService _inquiryService = InquiryService();

  Stream<DocumentSnapshot<Map<String, dynamic>>> get serviceStream {
    return firestore.collection('services').doc(widget.serviceId).snapshots();
  }

  Future<String> _loadCustomerPhone(String customerId) async {
    final customerDoc = await firestore
        .collection(FirestoreCollections.customers)
        .doc(customerId)
        .get();
    final customerPhone = _stringValue(customerDoc.data() ?? {}, 'phone');

    if (customerPhone.isNotEmpty) {
      return customerPhone;
    }

    final userDoc = await firestore
        .collection(FirestoreCollections.users)
        .doc(customerId)
        .get();

    return _stringValue(userDoc.data() ?? {}, 'phone');
  }

  Future<void> _showInquirySheet(Map<String, dynamic> serviceData) async {
    final messageController = TextEditingController();
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> sendInquiry() async {
              final user = auth.currentUser;

              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login first')),
                );
                return;
              }

              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your inquiry')),
                );
                return;
              }

              setModalState(() {
                isSending = true;
              });

              try {
                final customerName = user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : (user.email ?? 'Customer');

                await _inquiryService.createInquiry(
                  InquiryModel(
                    id: '',
                    customerId: user.uid,
                    customerName: customerName,
                    vendorId: _stringValue(serviceData, 'vendorId'),
                    serviceId: widget.serviceId,
                    serviceName: _stringValue(serviceData, 'name'),
                    message: messageController.text.trim(),
                    status: InquiryStatus.pending,
                    createdAt: DateTime.now(),
                  ),
                  additionalData: {
                    'customerEmail': user.email ?? '',
                    'vendorName': _stringValue(serviceData, 'vendorName'),
                  },
                );

                if (!mounted) return;

                Navigator.pop(sheetContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inquiry sent successfully')),
                );
              } catch (error) {
                setModalState(() {
                  isSending = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send inquiry: $error')),
                );
              }
            }

            return _BottomInputSheet(
              title: 'Send Inquiry',
              subtitle: _stringValue(serviceData, 'name'),
              child: Column(
                children: [
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Your Inquiry',
                      hintText: 'Ask about availability, price, package, etc.',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending ? null : sendInquiry,
                      child: isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Inquiry'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    messageController.dispose();
  }

  Future<void> _showBookingSheet(Map<String, dynamic> serviceData) async {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final noteController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    bool isBooking = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> bookNow() async {
              final user = auth.currentUser;

              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login first')),
                );
                return;
              }

              if (selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an event date')),
                );
                return;
              }

              if (selectedTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an event time')),
                );
                return;
              }

              setModalState(() {
                isBooking = true;
              });

              try {
                final customerName = user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : (user.email ?? 'Customer');
                final customerPhone = await _loadCustomerPhone(user.uid);
                final requestedDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );
                final normalizedRequestedDateTime = _normalizeBookingDateTime(
                  requestedDateTime,
                );
                final slotAlreadyBooked = await _bookingService
                    .hasActiveBookingForSlot(
                      serviceId: widget.serviceId,
                      eventDate: normalizedRequestedDateTime,
                    );

                if (slotAlreadyBooked) {
                  setModalState(() {
                    isBooking = false;
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This service is already booked for the selected date and time. Please choose another time.',
                      ),
                    ),
                  );
                  return;
                }

                await _bookingService.createBooking(
                  BookingModel(
                    id: '',
                    customerId: user.uid,
                    customerName: customerName,
                    customerEmail: user.email ?? '',
                    customerPhone: customerPhone,
                    vendorId: _stringValue(serviceData, 'vendorId'),
                    vendorName: _stringValue(serviceData, 'vendorName'),
                    serviceId: widget.serviceId,
                    serviceName: _stringValue(serviceData, 'name'),
                    servicePrice: _doubleValue(serviceData, 'price'),
                    eventDate: normalizedRequestedDateTime,
                    eventTime: normalizedRequestedDateTime,
                    note: noteController.text.trim(),
                    status: BookingStatus.pending,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  additionalData: {
                    'requestedDate': dateController.text.trim(),
                    'requestedTime': timeController.text.trim(),
                    'requestedDateTime': Timestamp.fromDate(
                      normalizedRequestedDateTime,
                    ),
                    'price': _doubleValue(serviceData, 'price'),
                  },
                );

                if (!mounted) return;

                Navigator.pop(sheetContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking request sent')),
                );
              } catch (error) {
                setModalState(() {
                  isBooking = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to book: $error')),
                );
              }
            }

            return _BottomInputSheet(
              title: 'Book Service',
              subtitle: _stringValue(serviceData, 'name'),
              child: Column(
                children: [
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    onTap: () async {
                      final now = DateTime.now();

                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 2),
                      );

                      if (pickedDate != null) {
                        setModalState(() {
                          selectedDate = pickedDate;

                          dateController.text =
                              '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Event Date',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: timeController,
                    readOnly: true,
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (pickedTime != null) {
                        setModalState(() {
                          selectedTime = pickedTime;
                          timeController.text = pickedTime.format(context);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Event Time',
                      prefixIcon: Icon(Icons.access_time_outlined),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Booking Note',
                      hintText: 'Write your event details...',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBooking ? null : bookNow,
                      child: isBooking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Booking Request'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    dateController.dispose();
    timeController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: serviceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Service Details')),
            body: const Center(child: Text('Service not found')),
          );
        }

        final serviceData = snapshot.data!.data() ?? {};

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroSection(
                      imageUrl: _imageValue(serviceData),
                      category: _stringValue(serviceData, 'category'),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TitleArea(serviceData: serviceData),

                            const SizedBox(height: 14),

                            _RatingLocationRow(serviceData: serviceData),

                            const SizedBox(height: 16),

                            _TagWrap(serviceData: serviceData),

                            const SizedBox(height: 24),

                            const _SectionTitle('About'),

                            const SizedBox(height: 10),

                            Text(
                              _stringValue(
                                serviceData,
                                'description',
                                fallback:
                                    'No description has been added for this service yet.',
                              ),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),

                            _SocialLogoLinksSection(serviceData: serviceData),

                            const SizedBox(height: 14),

                            const _SectionTitle('Reach Out'),

                            const SizedBox(height: 18),

                            _SocialLogoLinksSection(serviceData: serviceData),

                            const SizedBox(height: 26),

                            const _SectionTitle('Packages'),

                            const SizedBox(height: 14),

                            _PackageList(serviceData: serviceData),

                            const SizedBox(height: 28),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _SectionTitle('Reviews'),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Coming soon!'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('See all'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            _ReviewsList(serviceId: widget.serviceId),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                left: 22,
                right: 22,
                bottom: 16,
                child: _BottomActionBar(
                  onInquiry: () => _showInquirySheet(serviceData),
                  onBookNow: () => _showBookingSheet(serviceData),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String imageUrl;
  final String category;

  const _HeroSection({required this.imageUrl, required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isEmpty
              ? Container(
                  color: AppColors.selectedSurface,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: AppColors.selectedSurface,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),

          Container(color: Colors.black.withValues(alpha: 0.25)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.favorite_border,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.share_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 22,
            bottom: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                category.isEmpty ? 'Service' : category,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 20,
        color: Colors.white,
      ),
    );
  }
}

class _TitleArea extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _TitleArea({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stringValue(serviceData, 'name'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _stringValue(serviceData, 'vendorName'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _RatingLocationRow extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _RatingLocationRow({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final rating = _doubleValue(serviceData, 'averageRating');
    final reviewCount = _intValue(serviceData, 'totalReviews');

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount reviews)',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Container(height: 18, width: 1, color: AppColors.border),
        const SizedBox(width: 12),
        const Icon(
          Icons.location_on_outlined,
          size: 17,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _stringValue(serviceData, 'location'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _TagWrap({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final tags = _listValue(serviceData, 'tags');

    if (tags.isEmpty) {
      final category = _stringValue(serviceData, 'category');

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _TagChip(text: category.isEmpty ? 'Wedding' : category),
          const _TagChip(text: 'Indoor'),
          const _TagChip(text: 'Outdoor'),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _TagChip(text: tag)).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;

  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackageList extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _PackageList({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final packages = serviceData['packages'];

    if (packages is List && packages.isNotEmpty) {
      return Column(
        children: packages.map((package) {
          final packageData = Map<String, dynamic>.from(package as Map);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PackageCard(
              title: _stringValue(packageData, 'title', fallback: 'Package'),
              price: _stringValue(
                packageData,
                'price',
                fallback:
                    'Rs. ${_doubleValue(serviceData, 'price').toStringAsFixed(0)}',
              ),
              features: _listValue(packageData, 'features'),
            ),
          );
        }).toList(),
      );
    }

    return _PackageCard(
      title: 'Standard',
      price: 'Rs. ${_doubleValue(serviceData, 'price').toStringAsFixed(0)}',
      features: const [
        'Basic wedding service',
        'Vendor coordination',
        'Customizable package',
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final String serviceId;

  const _ReviewsList({required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('serviceId', isEqualTo: serviceId)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No reviews yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: reviews.map((doc) {
            final data = doc.data();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(reviewData: data),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> reviewData;

  const _ReviewCard({required this.reviewData});

  @override
  Widget build(BuildContext context) {
    final name = _stringValue(reviewData, 'customerName', fallback: 'Customer');
    final rating = _doubleValue(reviewData, 'rating');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              name.isEmpty ? 'C' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stringValue(
                    reviewData,
                    'comment',
                    fallback: 'No review comment added.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onInquiry;
  final VoidCallback onBookNow;

  const _BottomActionBar({required this.onInquiry, required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: onInquiry,
                icon: const Icon(Icons.edit_note),
                label: const Text('Inquiry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Book Now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInputSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _BottomInputSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _stringValue(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final value = data[key];

  if (value == null) return fallback;

  final text = value.toString().trim();

  if (text.isEmpty) return fallback;

  return text;
}

double _doubleValue(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value is num) return value.toDouble();

  return double.tryParse(value.toString()) ?? 0;
}

int _intValue(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value is int) return value;

  if (value is num) return value.toInt();

  return int.tryParse(value.toString()) ?? 0;
}

List<String> _listValue(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return [];
}

String _imageValue(Map<String, dynamic> data) {
  final imageUrl = data['imageUrl'];

  if (imageUrl is String && imageUrl.trim().isNotEmpty) {
    return imageUrl.trim();
  }

  final images = data['images'];

  if (images is List && images.isNotEmpty) {
    return images.first.toString();
  }

  return '';
}

DateTime _normalizeBookingDateTime(DateTime dateTime) {
  return DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour,
    dateTime.minute,
  );
}

class _SocialLogoLinksSection extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _SocialLogoLinksSection({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    final website = _socialValue(
      serviceData,
      'website',
      fallbackKeys: ['websiteUrl', 'vendorWebsite'],
    );

    final instagram = _socialValue(
      serviceData,
      'instagram',
      fallbackKeys: ['instagramUrl', 'vendorInstagram'],
    );

    final facebook = _socialValue(
      serviceData,
      'facebook',
      fallbackKeys: ['facebookUrl', 'vendorFacebook'],
    );

    final tiktok = _socialValue(
      serviceData,
      'tiktok',
      fallbackKeys: ['tiktokUrl', 'vendorTiktok'],
    );

    final whatsapp = _socialValue(
      serviceData,
      'whatsapp',
      fallbackKeys: ['whatsappUrl', 'vendorWhatsapp'],
    );

    final phone = _socialValue(
      serviceData,
      'phone',
      fallbackKeys: ['vendorPhone', 'contactNumber'],
    );

    final email = _socialValue(
      serviceData,
      'email',
      fallbackKeys: ['vendorEmail', 'contactEmail'],
    );

    final hasLinks = [
      website,
      instagram,
      facebook,
      tiktok,
      whatsapp,
      phone,
      email,
    ].any((value) => value.trim().isNotEmpty);

    if (!hasLinks) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Connect'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (website.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.globe,
                tooltip: 'Website',
                onTap: () => _openNormalLink(context, website),
              ),
            if (instagram.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.instagram,
                tooltip: 'Instagram',
                onTap: () => _openNormalLink(context, instagram),
              ),
            if (facebook.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.facebookF,
                tooltip: 'Facebook',
                onTap: () => _openNormalLink(context, facebook),
              ),
            if (tiktok.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.tiktok,
                tooltip: 'TikTok',
                onTap: () => _openNormalLink(context, tiktok),
              ),
            if (whatsapp.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.whatsapp,
                tooltip: 'WhatsApp',
                onTap: () => _openWhatsApp(context, whatsapp),
              ),
            if (phone.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.phone,
                tooltip: 'Call',
                onTap: () => _openPhone(context, phone),
              ),
            if (email.isNotEmpty)
              _SocialLogoButton(
                icon: FontAwesomeIcons.envelope,
                tooltip: 'Email',
                onTap: () => _openEmail(context, email),
              ),
          ],
        ),
      ],
    );
  }
}

class _SocialLogoButton extends StatelessWidget {
  final dynamic icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SocialLogoButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.selectedSurface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: FaIcon(icon, size: 20, color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

String _socialValue(
  Map<String, dynamic> data,
  String key, {
  List<String> fallbackKeys = const [],
}) {
  final socialLinks = data['socialLinks'];

  if (socialLinks is Map && socialLinks[key] != null) {
    final value = socialLinks[key].toString().trim();

    if (value.isNotEmpty) {
      return value;
    }
  }

  for (final fallbackKey in fallbackKeys) {
    final value = data[fallbackKey];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }

  return '';
}

Future<void> _openNormalLink(BuildContext context, String link) async {
  String fixedLink = link.trim();

  if (!fixedLink.startsWith('http://') && !fixedLink.startsWith('https://')) {
    fixedLink = 'https://$fixedLink';
  }

  final uri = Uri.tryParse(fixedLink);

  if (uri == null) {
    _showLinkError(context);
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    _showLinkError(context);
  }
}

Future<void> _openWhatsApp(BuildContext context, String value) async {
  String link = value.trim();

  if (!link.startsWith('http://') && !link.startsWith('https://')) {
    final number = link.replaceAll(RegExp(r'[^0-9]'), '');
    link = 'https://wa.me/$number';
  }

  await _openNormalLink(context, link);
}

Future<void> _openPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.trim());

  final opened = await launchUrl(uri);

  if (!opened && context.mounted) {
    _showLinkError(context);
  }
}

Future<void> _openEmail(BuildContext context, String email) async {
  final uri = Uri(scheme: 'mailto', path: email.trim());

  final opened = await launchUrl(uri);

  if (!opened && context.mounted) {
    _showLinkError(context);
  }
}

void _showLinkError(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Could not open this link')));
}
