import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class DrawingCard extends StatelessWidget {
  final String fileName;
  final DateTime uploadDate;
  final VoidCallback? onTap;

  const DrawingCard({
    super.key,
    required this.fileName,
    required this.uploadDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.folder, size: 28, color: AppColors.primaryText),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(uploadDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color:AppColors.primaryText ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}."
        "${date.month.toString().padLeft(2, '0')}."
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }
}
