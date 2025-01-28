import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:goplayer/data/ima_state.dart';

class IMAView extends StatelessWidget {
  final IMAState state;
  const IMAView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      key: ValueKey(state.hashCode),
      listenable: state,
      builder: (context, child) {
        if (state.shouldShowVideo) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: state.adDisplayContainer,
              ),
              _posterView,
              if (state.showAdsLoading) _adsLoadingWidget,
            ],
          ),
        );
      },
    );
  }

  Widget get _posterView {
    if (state.poster == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: state.poster!,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget get _adsLoadingWidget {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox.fromSize(
            size: const Size.square(60),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
