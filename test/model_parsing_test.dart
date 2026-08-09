import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wedding_essentialsapp/models/app_enums.dart';
import 'package:wedding_essentialsapp/models/booking_model.dart';
import 'package:wedding_essentialsapp/models/notification_model.dart';
import 'package:wedding_essentialsapp/models/service_model.dart';

void main() {
  test('BookingModel accepts legacy customer booking field names', () {
    final requestedDate = DateTime(2026, 1, 15, 10, 30);

    final booking = BookingModel.fromMap('booking-1', {
      'customerId': 'customer-1',
      'customerName': 'Customer Name',
      'vendorId': 'vendor-1',
      'serviceId': 'service-1',
      'serviceName': 'Photography',
      'price': '50,000',
      'requestedDateTime': Timestamp.fromDate(requestedDate),
      'status': 'cancelled',
    });

    expect(booking.servicePrice, 50000);
    expect(booking.eventDate, requestedDate);
    expect(booking.status, BookingStatus.rejected);
  });

  test('ServiceModel tolerates flexible numeric and list values', () {
    final service = ServiceModel.fromMap('service-1', {
      'vendorId': 'vendor-1',
      'vendorName': 'Vendor',
      'name': 'Decor',
      'price': '25,500',
      'imageUrls': 'https://example.com/image.jpg',
      'isActive': 'true',
    });

    expect(service.price, 25500);
    expect(service.imageUrls, ['https://example.com/image.jpg']);
    expect(service.isActive, isTrue);
  });

  test('NotificationModel parses string notification types safely', () {
    final notification = NotificationModel.fromMap('notification-1', {
      'title': 'New inquiry',
      'message': 'A customer contacted you.',
      'type': 'booking',
      'isRead': 'false',
    });

    expect(notification.type, NotificationType.booking);
    expect(notification.isRead, isFalse);
  });
}
