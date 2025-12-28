// ignore_for_file: unnecessary_underscores

import 'package:auto_service/data/models/auto_service_model.dart';
import 'package:auto_service/data/repositories/auto_services_repository.dart';
import 'package:auto_service/presentation/providers/auth_providers.dart';
import 'package:auto_service/presentation/screens/services/add_service_screen.dart';

import 'package:auto_service/data/models/review_model.dart';
import 'package:auto_service/data/repositories/reviews_repository.dart';
import 'package:auto_service/presentation/widgets/review_item_widget.dart';
import 'package:auto_service/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceDetailScreen extends StatefulWidget {
  final AutoServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late AutoServiceModel _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _loadFullServiceDetails();
  }

  Future<void> _loadFullServiceDetails() async {
    try {
      final fullDetails = await AutoServicesRepository().getServiceDetails(
        int.parse(widget.service.id),
      );
      if (fullDetails != null && mounted) {
        setState(() {
          _service = fullDetails;
        });
      }
    } catch (e) {
      debugPrint('Error loading full details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isOwner =
        authProvider.isAuthenticated &&
        authProvider.userProfile?.id != null &&
        _service.ownerId == authProvider.userProfile!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_service.name),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEdit(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, authProvider),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery or Main Image
            _buildGallery(isOwner, authProvider),

            const SizedBox(height: 16),

            // Main Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _service.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _service.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      _service.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contact Info
            _buildSection(
              title: 'contact_info'.tr(),
              icon: Icons.contact_phone,
              child: Column(
                children: [
                  if (_service.phone != null)
                    _buildContactItem(
                      icon: Icons.phone,
                      label: 'phone'.tr(),
                      value: _service.phone!,
                      onTap: () => _makePhoneCall(_service.phone!, context),
                    ),
                  if (_service.address != null)
                    _buildContactItem(
                      icon: Icons.location_on,
                      label: 'address'.tr(),
                      value: _service.address!,
                      onTap: () => _navigateToMap(
                        _service.latitude,
                        _service.longitude,
                        context,
                      ),
                    ),
                  if (_service.workingHours != null)
                    _buildContactItem(
                      icon: Icons.access_time,
                      label: 'working_hours'.tr(),
                      value: _service.workingHours!,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Working Hours & Days Section
            if (_service.startTime != null || _service.workingDays != null)
              _buildSection(
                title: 'working_hours'.tr(),
                icon: Icons.schedule,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Working Time
                    if (_service.startTime != null && _service.endTime != null)
                      Text(
                        '${_service.startTime} - ${_service.endTime}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    if (_service.workingDays != null &&
                        _service.workingDays!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'working_days'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDayChip(
                            1,
                            'monday',
                            _service.workingDays!.contains(1),
                          ),
                          _buildDayChip(
                            2,
                            'tuesday',
                            _service.workingDays!.contains(2),
                          ),
                          _buildDayChip(
                            3,
                            'wednesday',
                            _service.workingDays!.contains(3),
                          ),
                          _buildDayChip(
                            4,
                            'thursday',
                            _service.workingDays!.contains(4),
                          ),
                          _buildDayChip(
                            5,
                            'friday',
                            _service.workingDays!.contains(5),
                          ),
                          _buildDayChip(
                            6,
                            'saturday',
                            _service.workingDays!.contains(6),
                          ),
                          _buildDayChip(
                            7,
                            'sunday',
                            _service.workingDays!.contains(7),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Services List
            if (_service.services.isNotEmpty)
              _buildSection(
                title: 'services'.tr(),
                icon: Icons.build,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _service.services.map((serviceItem) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        serviceItem.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Extra Services (Дополнительные услуги)
            if (_service.extraServices != null &&
                _service.extraServices!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: 'extra_services'.tr(),
                icon: Icons.add_circle_outline,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _service.extraServices!.map((extraService) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            extraService.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Navigation Buttons
            Row(
              children: [
                // Route Button
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {
                          'latitude': _service.latitude,
                          'longitude': _service.longitude,
                          'buildRoute': true,
                        });
                      },
                      icon: const Icon(Icons.directions, size: 22),
                      label: Text(
                        'build_route'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            _buildReviewsSection(authProvider),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- Reviews Section ---

  // State for reviews
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reviews.isEmpty) {
      _fetchReviews();
    }
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ReviewsRepository().getServiceReviews(
        int.parse(_service.id),
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Widget _buildReviewsSection(AuthProvider authProvider) {
    final isOwner =
        authProvider.isAuthenticated &&
        authProvider.userProfile?.id != null &&
        _service.ownerId == authProvider.userProfile!.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'reviews'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (authProvider.isAuthenticated)
              TextButton.icon(
                onPressed: () => _showAddReviewDialog(authProvider),
                icon: const Icon(Icons.rate_review),
                label: Text('write_review'.tr()),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('no_reviews_yet'.tr()),
          )
        else
          ..._reviews.map((review) {
            final isMyReview =
                authProvider.isAuthenticated &&
                authProvider.userProfile?.id != null &&
                review.user == authProvider.userProfile!.id;

            return ReviewItemWidget(
              review: review,
              isMyReview: isMyReview,
              isOwner: isOwner,
              onEdit: () => _showEditReviewDialog(review),
              onDelete: () => _deleteReview(review.id),
              onAddResponse: authProvider.isAuthenticated
                  ? (responseText) =>
                        _addReviewResponse(review.id, responseText)
                  : null,
              onDeleteResponse: isOwner
                  ? (response) => _deleteReviewResponse(response.id)
                  : null,
              onToggleLike: authProvider.isAuthenticated
                  ? (isLike) => _toggleReviewLike(review.id, isLike)
                  : null,
            );
          }),
      ],
    );
  }

  Future<void> _deleteReview(int reviewId) async {
    try {
      final success = await ReviewsRepository().deleteReview(reviewId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('review_deleted'.tr())));
          _fetchReviews();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('error_deleting_review'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
      }
    }
  }

  Future<void> _addReviewResponse(int reviewId, String responseText) async {
    try {
      final response = await ReviewsRepository().createReviewResponse(
        reviewId: reviewId,
        responseText: responseText,
      );

      if (mounted) {
        if (response != null) {
          // Обновляем список отзывов чтобы показать новый ответ
          _fetchReviews();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('error_adding_response'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
      }
    }
  }

  Future<void> _deleteReviewResponse(int responseId) async {
    try {
      final success = await ReviewsRepository().deleteReviewResponse(
        responseId,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('response_deleted'.tr())));
          _fetchReviews();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_deleting_response'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
      }
    }
  }

  Future<void> _toggleReviewLike(int reviewId, bool isLike) async {
    try {
      final success = await ReviewsRepository().toggleReviewLike(
        reviewId: reviewId,
        isLike: isLike,
      );
      if (mounted && success) {
        // Обновляем список отзывов чтобы показать новые лайки/дизлайки
        _fetchReviews();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
      }
    }
  }

  Future<void> _showAddReviewDialog(AuthProvider authProvider) async {
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    int overallScore = 5;
    int qualityScore = 5;
    int priceScore = 5;
    int staffScore = 5;
    int locationScore = 5;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('write_review'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'title'.tr()),
                ),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(labelText: 'comment'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildRatingSlider(
                  'rating_overall'.tr(),
                  overallScore,
                  (v) => setState(() => overallScore = v),
                ),
                _buildRatingSlider(
                  'rating_quality'.tr(),
                  qualityScore,
                  (v) => setState(() => qualityScore = v),
                ),
                _buildRatingSlider(
                  'rating_price'.tr(),
                  priceScore,
                  (v) => setState(() => priceScore = v),
                ),
                _buildRatingSlider(
                  'rating_staff'.tr(),
                  staffScore,
                  (v) => setState(() => staffScore = v),
                ),
                _buildRatingSlider(
                  'rating_location'.tr(),
                  locationScore,
                  (v) => setState(() => locationScore = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final create = ReviewCreate(
                    service: int.parse(_service.id),
                    title: titleController.text,
                    comment: commentController.text,
                    overallRating: overallScore,
                    qualityRating: qualityScore,
                    priceRating: priceScore,
                    staffRating: staffScore,
                    locationRating: locationScore,
                  );
                  final success = await ReviewsRepository().createReview(
                    create,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('review_submitted'.tr())),
                      );
                      _fetchReviews();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('error_creating_review'.tr())),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: Text('add'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditReviewDialog(Review review) async {
    final titleController = TextEditingController(text: review.title);
    final commentController = TextEditingController(text: review.comment);
    int overallScore = review.overallRating > 0 ? review.overallRating : 5;
    int qualityScore = review.qualityRating > 0 ? review.qualityRating : 5;
    int priceScore = review.priceRating > 0 ? review.priceRating : 5;
    int staffScore = review.staffRating > 0 ? review.staffRating : 5;
    int locationScore = review.locationRating > 0 ? review.locationRating : 5;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'write_review'.tr(),
          ), // Using same title "Write/Edit Review"
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'title'.tr()),
                ),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(labelText: 'comment'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildRatingSlider(
                  'rating_overall'.tr(),
                  overallScore,
                  (v) => setState(() => overallScore = v),
                ),
                _buildRatingSlider(
                  'rating_quality'.tr(),
                  qualityScore,
                  (v) => setState(() => qualityScore = v),
                ),
                _buildRatingSlider(
                  'rating_price'.tr(),
                  priceScore,
                  (v) => setState(() => priceScore = v),
                ),
                _buildRatingSlider(
                  'rating_staff'.tr(),
                  staffScore,
                  (v) => setState(() => staffScore = v),
                ),
                _buildRatingSlider(
                  'rating_location'.tr(),
                  locationScore,
                  (v) => setState(() => locationScore = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success = await ReviewsRepository().updateReview(
                    reviewId: review.id,
                    title: titleController.text,
                    comment: commentController.text,
                    overallRating: overallScore,
                    qualityRating: qualityScore,
                    priceRating: priceScore,
                    staffRating: staffScore,
                    locationRating: locationScore,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('review_submitted'.tr())),
                      );
                      _fetchReviews();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('error_creating_review'.tr())),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: Text('update'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 4,
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        Text(value.toString()),
      ],
    );
  }

  Widget _buildGallery(bool isOwner, AuthProvider authProvider) {
    // Collect all images: main imageUrl + additional images
    final allImages = <String>[];

    // Добавляем изображения из массива images (используем новый метод)
    for (final img in _service.images) {
      allImages.add(img.getFullImageUrl());
    }

    // Fallback на старое поле imageUrl если нет изображений
    if (allImages.isEmpty && _service.imageUrl != null) {
      final baseUrl = ApiConfig.baseUrl;
      if (_service.imageUrl!.startsWith('http')) {
        allImages.add(_service.imageUrl!);
      } else if (_service.imageUrl!.startsWith('/')) {
        allImages.add('$baseUrl${_service.imageUrl}');
      } else {
        allImages.add('$baseUrl/${_service.imageUrl}');
      }
    }

    if (allImages.isEmpty && !isOwner) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.business, size: 50),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (allImages.isNotEmpty)
          Center(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
                shrinkWrap: true,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      allImages[index],
                      width: 300,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
          ),

        if (isOwner)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () => _uploadImage(context, authProvider),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photo'),
            ),
          ),
      ],
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(serviceToEdit: _service),
      ),
    );

    if (result == true) {
      // Refresh logic? Ideally we fetch updated service.
      // For now we might just pop or try to reload context if possible.
      // But we don't have a specific "getServiceById" in repo used here yet easily.
      // We can pop with indication to reload list.
      if (context.mounted) {
        Navigator.pop(context, true); // Pop to list to refresh
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_service'.tr()),
        content: Text('delete_service_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await AutoServicesRepository().deleteService(
        id: int.parse(_service.id),
      );

      if (context.mounted) {
        if (success) {
          Navigator.pop(context, true); // Pop and refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_deleting_service'.tr())),
          );
        }
      }
    }
  }

  Future<void> _uploadImage(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

      final success = await AutoServicesRepository().addServiceImage(
        serviceId: int.parse(_service.id),
        imagePath: image.path,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded! Refresh to see.')),
          );
          // Ideally trigger refresh of screen
          Navigator.pop(context, true); // Simple way to force refresh from list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error uploading image')),
          );
        }
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDayChip(int day, String labelKey, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue[800]! : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        labelKey.tr(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? Colors.white : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    try {
      // Очищаем номер от всех символов кроме цифр и +
      final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final uri = Uri(scheme: 'tel', path: cleaned);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось открыть приложение телефона'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Переход на карту с построением маршрута
  void _navigateToMap(double latitude, double longitude, BuildContext context) {
    debugPrint('🔹 Адрес нажат, возвращаем координаты: $latitude, $longitude');
    // Используем тот же механизм, что и кнопка "Построить маршрут"
    Navigator.pop(context, {
      'latitude': latitude,
      'longitude': longitude,
      'buildRoute': true,
    });
  }
}
