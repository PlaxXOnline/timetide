import 'package:flutter/widgets.dart';

import '../../core/models/resource.dart';
import '../../theme/tide_theme.dart';

/// Default resource header widget for timeline views.
///
/// Displays the resource name, a color indicator circle, and an optional
/// avatar image. Uses only `widgets.dart` — no Material or Cupertino imports.
class TideResourceHeader extends StatelessWidget {
  /// Creates a [TideResourceHeader].
  const TideResourceHeader({
    super.key,
    required this.resource,
    this.width,
    this.height,
  });

  /// The resource to display.
  final TideResource resource;

  /// Optional fixed width. If null, uses available width from parent.
  final double? width;

  /// Optional fixed height. If null, uses intrinsic height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = TideTheme.of(context);

    return Semantics(
      label: 'Resource: ${resource.displayName}',
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(
            right: BorderSide(
              color: theme.resourceDividerColor,
              width: theme.resourceDividerWidth,
            ),
            bottom: BorderSide(
              color: theme.resourceDividerColor,
              width: theme.resourceDividerWidth,
            ),
          ),
        ),
        child: Row(
          children: [
            // Color indicator circle
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: resource.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Avatar (optional)
            if (resource.avatar != null) ...[
              ClipOval(
                child: Image(
                  image: resource.avatar!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Name
            Expanded(
              child: Text(
                resource.displayName,
                style: theme.dayHeaderTextStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
