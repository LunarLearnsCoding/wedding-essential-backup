import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_information_sheet.dart';
import '../../core/constants/firestore_collections.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../models/inquiry_model.dart';
import '../../services/booking_service.dart';
import '../../services/favorites_service.dart';
import '../../services/inquiry_service.dart';
import 'vendor_details_screen.dart';

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

                  await showAppInformationSheet(
                    context,
                    title: 'Time slot unavailable',
                    message:
                        'This service already has a booking for the selected date and time. Please choose another available time.',
                    icon: Icons.event_busy_outlined,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceImageGallery(
                  serviceId: widget.serviceId,
                  vendorId: _stringValue(serviceData, 'vendorId'),
                  imageUrls: _serviceImages(serviceData),
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
                        Text(
                          _stringValue(serviceData, 'category'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        _TitleArea(serviceData: serviceData),

                        const SizedBox(height: 6),

                        _VendorLocationRow(serviceData: serviceData),

                        const SizedBox(height: 16),

                        _StartingPrice(serviceData: serviceData),

                        const SizedBox(height: 20),

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

                        const SizedBox(height: 20),

                        _VendorInfoSection(
                          vendorId: _stringValue(serviceData, 'vendorId'),
                          fallbackName: _stringValue(
                            serviceData,
                            'vendorName',
                            fallback: 'Vendor',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: _BottomActionBar(
              onInquiry: () => _showInquirySheet(serviceData),
              onBookNow: () => _showBookingSheet(serviceData),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceImageGallery extends StatefulWidget {
  final String serviceId;
  final String vendorId;
  final List<String> imageUrls;
  const _ServiceImageGallery({
    required this.serviceId,
    required this.vendorId,
    required this.imageUrls,
  });
  @override
  State<_ServiceImageGallery> createState() => _ServiceImageGalleryState();
}

class _ServiceImageGalleryState extends State<_ServiceImageGallery> {
  final FavoritesService _favoritesService = FavoritesService();
  late Stream<bool> _favoriteStream;
  int _currentPage = 0;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _favoriteStream = _favoritesService.isFavorite(widget.serviceId);
  }

  @override
  void didUpdateWidget(covariant _ServiceImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceId != widget.serviceId) {
      _favoriteStream = _favoritesService.isFavorite(widget.serviceId);
    }
  }

  Future<void> _toggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      await _favoritesService.toggleFavorite(
        serviceId: widget.serviceId,
        vendorId: widget.vendorId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites.')),
      );
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.imageUrls.isEmpty
              ? Container(
                  color: AppColors.selectedSurface,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                )
              : PageView.builder(
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.selectedSurface,
                      child: const Icon(Icons.broken_image_outlined, size: 60),
                    ),
                  ),
                ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, right: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  iconColor: Colors.white,
                  backgroundColor: Colors.black38,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, right: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: StreamBuilder<bool>(
                  stream: _favoriteStream,
                  builder: (context, snapshot) {
                    final isInitiallyLoading =
                        snapshot.connectionState == ConnectionState.waiting;
                    return _CircleIconButton(
                      icon: snapshot.data == true
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: snapshot.data == true
                          ? AppColors.primary
                          : Colors.white,
                      backgroundColor: snapshot.data == true
                          ? Colors.white
                          : Colors.black38,
                      onTap: isInitiallyLoading || _isToggling ? null : _toggle,
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 26,
        color: iconColor,
        disabledColor: iconColor,
      ),
    );
  }
}

class _TitleArea extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _TitleArea({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return Text(
      _stringValue(serviceData, 'name'),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _VendorLocationRow extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const _VendorLocationRow({required this.serviceData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          flex: 4,
          child: Text(
            _stringValue(serviceData, 'vendorName', fallback: 'Vendor'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.location_on_outlined,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _stringValue(serviceData, 'location'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VendorInfoSection extends StatelessWidget {
  final String vendorId;
  final String fallbackName;
  const _VendorInfoSection({
    required this.vendorId,
    required this.fallbackName,
  });
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.vendors)
          .doc(vendorId)
          .snapshots(),
      builder: (context, vendorSnapshot) {
        final vendorData = vendorSnapshot.data?.data() ?? {};
        final businessName = _stringValue(vendorData, 'businessName');
        final vendorName = _stringValue(
          vendorData,
          'name',
          fallback: fallbackName,
        );
        return Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(businessName.isEmpty ? vendorName : businessName),
            trailing: const Text('View Vendor Profile'),
            onTap: vendorId.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorDetailsScreen(vendorId: vendorId),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _StartingPrice extends StatelessWidget {
  final Map<String, dynamic> serviceData;
  const _StartingPrice({required this.serviceData});
  @override
  Widget build(BuildContext context) {
    final price = _doubleValue(serviceData, 'price');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        price > 0
            ? 'Starting from Rs. ${price.toStringAsFixed(0)}'
            : 'Price not provided',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
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

List<String> _serviceImages(Map<String, dynamic> data) {
  final images = data['imageUrls'];
  if (images is Iterable) {
    final urls = images
        .map((item) => item.toString().trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) return urls;
  }
  final legacy = data['imageUrl']?.toString().trim() ?? '';
  return legacy.isEmpty ? const [] : [legacy];
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

// ignore: unused_element
