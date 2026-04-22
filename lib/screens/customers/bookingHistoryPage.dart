import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class BookingHistoryPage extends StatelessWidget {
  BookingHistoryPage({super.key});

  final FirestoreService _service = FirestoreService();

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'awaiting_customer_confirmation':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'issue_reported':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  Widget _ratingStars({
    required double rating,
    ValueChanged<double>? onChanged,
    double size = 22,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final isActive = rating >= starValue;
        return IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          onPressed: onChanged == null ? null : () => onChanged(starValue),
          icon: Icon(
            isActive ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }

  Future<void> _showReviewSheet({
    required BuildContext context,
    required String bookingId,
    required Map<String, dynamic> bookingData,
    Map<String, dynamic>? existingReview,
  }) async {
    double rating = (existingReview?['rating'] as num?)?.toDouble() ?? 5;
    final commentController = TextEditingController(
      text: existingReview?['comment']?.toString() ?? '',
    );
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate ${bookingData['serviceType'] ?? 'Service'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ratingStars(
                    rating: rating,
                    onChanged: (val) => setModalState(() => rating = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write a short review (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              try {
                                setModalState(() => submitting = true);
                                await _service.submitReview(
                                  bookingId: bookingId,
                                  rating: rating,
                                  comment: commentController.text,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Review submitted successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                                setModalState(() => submitting = false);
                              }
                            },
                      child: Text(
                        existingReview == null
                            ? 'Submit Review'
                            : 'Update Review',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getCustomerBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load bookings: ${snapshot.error}'),
            );
          }

          final bookings = [...(snapshot.data?.docs ?? [])];
          bookings.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = bookings[index].data();
              final serviceType = (data['serviceType'] as String?) ?? 'Service';
              final details = (data['details'] as String?) ?? '';
              final date = (data['date'] as String?) ?? '';
              final time = (data['time'] as String?) ?? '';
              final status = (data['status'] as String?) ?? 'pending';
              final amount = (data['estimatedAmount'] as num?)?.toDouble() ?? 0;
              final createdAt = data['createdAt'] as Timestamp?;
              final bookingId = bookings[index].id;
              final providerId = data['providerId']?.toString() ?? '';
              final statusLower = status.toLowerCase();
              final canReview = providerId.isNotEmpty && statusLower == 'completed';

              return FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                future: canReview
                    ? _service.getReviewForBooking(bookingId)
                    : Future.value(null),
                builder: (context, reviewSnapshot) {
                  final existingReviewDoc = reviewSnapshot.data;
                  final existingReview = existingReviewDoc?.data();
                  final existingRating =
                      (existingReview?['rating'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            serviceType,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '$details\n$date $time\nCreated: ${createdAt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('UGX ${amount.toStringAsFixed(0)}'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (statusLower == 'confirmed' ||
                            statusLower == 'awaiting_customer_confirmation')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirm Completion?'),
                                          content: const Text('Are you sure the provider has completed this job? Your wallet will be deducted and payment sent to the provider.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                                          ],
                                        ),
                                      ) ?? false;

                                      if (confirm && context.mounted) {
                                        try {
                                          await _service.confirmTaskCompleted(bookingId);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment sent. Task completed.')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Complete task'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final reason = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) {
                                          final ctrl = TextEditingController();
                                          return AlertDialog(
                                            title: const Text('Report Issue'),
                                            content: TextField(
                                              controller: ctrl,
                                              decoration: const InputDecoration(hintText: 'Reason for non-completion'),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                                              ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Submit')),
                                            ],
                                          );
                                        },
                                      );

                                      if (reason != null && reason.trim().isNotEmpty && context.mounted) {
                                        try {
                                          await _service.reportTaskDispute(bookingId, reason);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute reported to Admin.')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      }
                                    },
                                    child: const Text('Report issue', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (statusLower == 'completed' && canReview)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                if (existingReview != null)
                                  _ratingStars(rating: existingRating, size: 18),
                                if (existingReview != null)
                                  const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: () => _showReviewSheet(
                                    context: context,
                                    bookingId: bookingId,
                                    bookingData: data,
                                    existingReview: existingReview,
                                  ),
                                  icon: Icon(
                                    existingReview == null
                                        ? Icons.star_outline
                                        : Icons.edit,
                                    size: 18,
                                  ),
                                  label: Text(
                                    existingReview == null
                                        ? 'Rate Service'
                                        : 'Edit Review',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
