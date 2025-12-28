import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:auto_service/data/models/review_model.dart';

/// Виджет для отображения отзыва с ответами
class ReviewItemWidget extends StatefulWidget {
  final Review review;
  final bool isMyReview;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String responseText)? onAddResponse;
  final Function(ReviewResponse response)? onDeleteResponse;
<<<<<<< HEAD
  final Function(bool isLike)? onToggleLike;
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1

  const ReviewItemWidget({
    super.key,
    required this.review,
    this.isMyReview = false,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.onAddResponse,
    this.onDeleteResponse,
<<<<<<< HEAD
    this.onToggleLike,
=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
  });

  @override
  State<ReviewItemWidget> createState() => _ReviewItemWidgetState();
}

class _ReviewItemWidgetState extends State<ReviewItemWidget> {
  final bool _showResponseField = false;
  final TextEditingController _responseController = TextEditingController();
  final bool _isSubmitting = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
<<<<<<< HEAD
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
=======
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок отзыва
            _buildReviewHeader(),
<<<<<<< HEAD

            const SizedBox(height: 12),

            // Рейтинги
            _buildRatings(),

            const SizedBox(height: 12),

=======
            
            const SizedBox(height: 12),
            
            // Рейтинги
            _buildRatings(),
            
            const SizedBox(height: 12),
            
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
            // Заголовок отзыва
            if (widget.review.title.isNotEmpty) ...[
              Text(
                widget.review.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
            ],
<<<<<<< HEAD

            // Текст отзыва
            Text(
              widget.review.comment,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            const SizedBox(height: 12),

            // Кнопки действий
            _buildActionButtons(),

=======
            
            // Текст отзыва
            Text(
              widget.review.comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Кнопки действий
            _buildActionButtons(),
            
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
            // Ответы на отзыв
            if (widget.review.responses.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ..._buildResponses(),
            ],
<<<<<<< HEAD

=======
            
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
            // Поле для добавления ответа
            if (_showResponseField) ...[
              const SizedBox(height: 12),
              _buildResponseField(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      children: [
        // Аватар
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            widget.review.userName.isNotEmpty
                ? widget.review.userName[0].toUpperCase()
                : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
<<<<<<< HEAD

        const SizedBox(width: 12),

=======
        
        const SizedBox(width: 12),
        
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
        // Имя и дата
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.review.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'verified'.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.yMMMd().format(widget.review.createdAt),
<<<<<<< HEAD
                style: const TextStyle(color: Colors.grey, fontSize: 12),
=======
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
              ),
            ],
          ),
        ),
<<<<<<< HEAD

        // Общий рейтинг
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
=======
        
        // Общий рейтинг
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
          decoration: BoxDecoration(
            color: _getRatingColor(widget.review.overallRating),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
<<<<<<< HEAD
              const Icon(Icons.star, size: 16, color: Colors.white),
=======
              const Icon(
                Icons.star,
                size: 16,
                color: Colors.white,
              ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
              const SizedBox(width: 4),
              Text(
                widget.review.overallRating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
<<<<<<< HEAD

=======
        
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
        // Меню действий
        if (widget.isMyReview || widget.isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit' && widget.onEdit != null) {
                widget.onEdit!();
              } else if (value == 'delete' && widget.onDelete != null) {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              if (widget.isMyReview)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text('edit'.tr()),
                    ],
                  ),
                ),
              if (widget.isMyReview || widget.isOwner)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
<<<<<<< HEAD
                      Text(
                        'delete'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
=======
                      Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRatings() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildRatingChip('quality'.tr(), widget.review.qualityRating),
        _buildRatingChip('price'.tr(), widget.review.priceRating),
        _buildRatingChip('staff'.tr(), widget.review.staffRating),
        _buildRatingChip('location'.tr(), widget.review.locationRating),
      ],
    );
  }

  Widget _buildRatingChip(String label, int rating) {
<<<<<<< HEAD
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
=======
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
<<<<<<< HEAD
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, size: 12, color: _getRatingColor(rating)),
=======
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            size: 12,
            color: _getRatingColor(rating),
          ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
          const SizedBox(width: 2),
          Text(
            rating.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getRatingColor(rating),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Лайки
        TextButton.icon(
<<<<<<< HEAD
          onPressed: widget.onToggleLike != null
              ? () => widget.onToggleLike!(true)
              : null,
          icon: Icon(
            widget.review.userLike ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 16,
            color: widget.review.userLike ? Colors.blue : null,
          ),
          label: Text(
            '${widget.review.likesCount}',
            style: TextStyle(
              color: widget.review.userLike ? Colors.blue : null,
            ),
          ),
=======
          onPressed: () {
            // TODO: Implement like functionality
          },
          icon: Icon(
            widget.review.userLike ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 16,
          ),
          label: Text('${widget.review.likesCount}'),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
        ),
<<<<<<< HEAD

        // Дизлайки
        TextButton.icon(
          onPressed: widget.onToggleLike != null
              ? () => widget.onToggleLike!(false)
              : null,
=======
        
        // Дизлайки
        TextButton.icon(
          onPressed: () {
            // TODO: Implement dislike functionality
          },
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
          icon: const Icon(Icons.thumb_down_outlined, size: 16),
          label: Text('${widget.review.dislikesCount}'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
        ),
<<<<<<< HEAD

        const Spacer(),

        // Кнопка ответа (для всех авторизованных пользователей)
        if (widget.onAddResponse != null)
=======
        
        const Spacer(),
        
        // Кнопка ответа (только для владельца сервиса)
        if (widget.isOwner && widget.onAddResponse != null)
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showResponseField = !_showResponseField;
              });
            },
            icon: const Icon(Icons.reply, size: 16),
            label: Text('reply'.tr()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildResponses() {
<<<<<<< HEAD
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

=======
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
    return widget.review.responses.map((response) {
      return Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
<<<<<<< HEAD
          color: isDark
              ? Colors.grey[800]
              : theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.grey[700]!
                : theme.primaryColor.withOpacity(0.2),
          ),
=======
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
<<<<<<< HEAD
                Icon(Icons.person, size: 16, color: theme.primaryColor),
=======
                Icon(Icons.store, size: 16, color: Colors.blue[700]),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            response.ownerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
<<<<<<< HEAD
                              color: isDark ? Colors.white : theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Показываем бейдж "Owner" только если это владелец сервиса
                          if (widget.isOwner &&
                              response.owner == widget.review.service)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'owner'.tr(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
=======
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'owner'.tr(),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                        ],
                      ),
                      Text(
                        DateFormat.yMMMd().format(response.createdAt),
                        style: TextStyle(
<<<<<<< HEAD
                          color: isDark
                              ? Colors.grey[400]
                              : theme.primaryColor.withOpacity(0.7),
=======
                          color: Colors.blue[700],
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isOwner && widget.onDeleteResponse != null) {
                  IconButton(
<<<<<<< HEAD
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[400],
                    ),
=======
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                    onPressed: () => _confirmDeleteResponse(response),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                },
              ],
            ),
            const SizedBox(height: 8),
            Text(
              response.responseText,
              style: TextStyle(
                fontSize: 13,
<<<<<<< HEAD
                color: isDark ? Colors.white70 : Colors.black87,
=======
                color: Colors.blue[900],
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
                height: 1.4,
              ),
            ),
          ],
        ),
      )
    }).toList();
  }

  Widget _buildResponseField() {
<<<<<<< HEAD
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.grey[700]!) : null,
=======
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _responseController,
<<<<<<< HEAD
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'write_response'.tr(),
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.white,
=======
            decoration: InputDecoration(
              hintText: 'write_response'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 3,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _showResponseField = false;
                          _responseController.clear();
                        });
                      },
                child: Text('cancel'.tr()),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitResponse,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_isSubmitting ? 'sending'.tr() : 'send'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
<<<<<<< HEAD
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('response_empty'.tr())));
=======
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('response_empty'.tr())),
      );
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.onAddResponse != null) {
        await widget.onAddResponse!(_responseController.text.trim());
      }

      if (mounted) {
        setState(() {
          _showResponseField = false;
          _responseController.clear();
          _isSubmitting = false;
        });

<<<<<<< HEAD
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('response_added'.tr())));
=======
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('response_added'.tr())),
        );
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
<<<<<<< HEAD
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error_adding_response'.tr())));
=======
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_adding_response'.tr())),
        );
>>>>>>> 420a5290a84808305b67d14c3efa00a2302c11d1
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_review'.tr()),
        content: Text('delete_review_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteResponse(ReviewResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_response'.tr()),
        content: Text('delete_response_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onDeleteResponse != null) {
                widget.onDeleteResponse!(response);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
