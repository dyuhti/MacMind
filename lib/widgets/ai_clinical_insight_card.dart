import 'package:flutter/material.dart';

class AIClinicalInsightCard extends StatefulWidget {
  final bool isLoading;
  final List<String> insights;
  final String? warningMessage;
  final VoidCallback? onRetry;

  const AIClinicalInsightCard({
    super.key,
    required this.isLoading,
    required this.insights,
    this.warningMessage,
    this.onRetry,
  });

  @override
  State<AIClinicalInsightCard> createState() => _AIClinicalInsightCardState();
}

class _AIClinicalInsightCardState extends State<AIClinicalInsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(covariant AIClinicalInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.warningMessage != widget.warningMessage ||
        oldWidget.insights != widget.insights) {
      _fadeController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasWarning = (widget.warningMessage ?? '').trim().isNotEmpty;
    final w = MediaQuery.of(context).size.width;
    final int maxInsights = 4;
    final int maxChars = w < 360 ? 100 : (w < 420 ? 120 : 150);
    final displayedInsights = widget.insights.take(maxInsights).map((s) {
      var t = s.trim();
      if (t.length > maxChars) {
        final cut = t.substring(0, maxChars);
        final safe = cut.contains(' ') ? cut.substring(0, cut.lastIndexOf(' ')) : cut;
        t = '${safe.trimRight()}.';
      }
      return t;
    }).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7E6F8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFFE7F2FF),
                  child: Icon(
                    Icons.local_hospital_outlined,
                    color: Color(0xFF1C6ECF),
                    size: 14,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Clinical Insights',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.isLoading) const _LoadingShimmer(),
            if (!widget.isLoading && hasWarning) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE5B5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB7791F),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.warningMessage!,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1C6ECF),
                      side: const BorderSide(color: Color(0xFFBFD8F7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            if (!widget.isLoading && !hasWarning) ...[
              if (displayedInsights.isEmpty)
                const Text(
                  'No insights available.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                )
              else
                ListView.separated(
                  itemCount: displayedInsights.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => SizedBox(height: w < 360 ? 8 : 12),
                  itemBuilder: (context, index) {
                    final insight = displayedInsights[index];
                    return _InsightItem(text: insight);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String text;

  const _InsightItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double fontSize = w < 360 ? 11.5 : (w < 420 ? 12.0 : 12.5);
    final double lineHeight = w < 360 ? 1.35 : (w < 420 ? 1.45 : 1.55);
    final double bulletSize = w < 360 ? 12 : 14;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: bulletSize + 4,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            '\u2022',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: bulletSize,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C6ECF),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: fontSize,
              height: lineHeight,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer();

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.0 + (2.0 * _controller.value), 0),
                      end: Alignment(1.0 + (2.0 * _controller.value), 0),
                      colors: const [
                        Color(0xFFE7EDF6),
                        Color(0xFFF3F7FD),
                        Color(0xFFE7EDF6),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    width: double.infinity,
                    height: 12,
                    color: const Color(0xFFE7EDF6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
