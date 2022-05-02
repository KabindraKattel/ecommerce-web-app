import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tv/core/exceptions/exceptions.dart';
import 'package:tv/core/resources/color_constants.dart';

import 'lottie_icons/error_icon.dart';

class MyErrorWidget extends StatelessWidget {
  final String? error;
  final bool hideAnimation;
  final VoidCallback? onRetry;
  const MyErrorWidget({
    Key? key,
    this.error,
    this.onRetry,
    this.hideAnimation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!hideAnimation) ...[
              const Spacer(),
              const Flexible(
                child: ErrorIcon(),
              ),
            ],
            Text(
              error ?? const OtherException().message,
              style: const TextStyle(color: ColorConstants.kErrorRed),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh,
                  color: ColorConstants.kErrorRed,
                ),
              ),
            if (!hideAnimation) const Spacer(),
          ],
        ),
      ),
    );
  }
}
