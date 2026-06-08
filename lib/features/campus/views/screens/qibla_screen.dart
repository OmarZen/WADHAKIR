import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/cubit/qibla_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/repositories/qibla_repository_impl.dart';
import 'package:wadhakir/domain/usecases/get_qibla_direction_usecase.dart';
import 'package:wadhakir/domain/usecases/request_qibla_permissions_usecase.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_compass_widget.dart';
import 'package:wadhakir/features/campus/views/screens/qibla_ar_screen.dart';
import 'package:wadhakir/features/azkar/views/widgets/islamic_pattern_painter.dart';

// Modern color scheme for Qibla screen that matches the app theme
const Color qiblaBaseColor = Color(0xFF20497D); // Primary blue
const Color qiblaPrimaryColor = Color(0xFF3498DB); // Bright blue
const Color qiblaAccentColor = Color(0xFFDAA520); // Gold
const Color qiblaDarkAccentColor = Color(0xFFD35400); // Dark orange

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final QiblaRepositoryImpl qiblaRepository;
  late final GetQiblaDirectionUseCase getQiblaDirectionUseCase;
  late final RequestQiblaPermissionsUseCase requestQiblaPermissionsUseCase;
  late final QiblaCubit qiblaCubit;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize synchronously to avoid late initialization error
    qiblaRepository = QiblaRepositoryImpl();
    getQiblaDirectionUseCase = GetQiblaDirectionUseCase(qiblaRepository);
    requestQiblaPermissionsUseCase = RequestQiblaPermissionsUseCase(
      qiblaRepository,
    );
    qiblaCubit = QiblaCubit(
      getQiblaDirectionUseCase,
      requestQiblaPermissionsUseCase,
      qiblaRepository,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();

    // Check compass availability and request permissions after a delay
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    // Wait for repository to complete initialization and compass check
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if compass is available first
    if (!qiblaRepository.isCompassAvailable) {
      // Trigger cubit to check and emit error state
      if (mounted) {
        qiblaCubit.getQiblaDirection();
      }
      return;
    }

    // Only request location permission if compass is available
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      if (mounted) {
        _showLocationServiceDialog();
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Show dialog that permission is needed
        if (mounted) {
          _showPermissionRequiredDialog();
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      if (mounted) {
        _showOpenSettingsDialog();
      }
      return;
    }

    // Permission granted, start the Qibla direction
    qiblaCubit.getQiblaDirection();
  }

  void _showLocationServiceDialog() {
    final l10n = context.l10n;
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        title: Text(
          l10n?.translate('campus.location_service_disabled') ??
              'خدمة الموقع معطلة',
        ),
        body: Text(
          l10n?.translate('campus.enable_location_service') ??
              'يرجى تفعيل خدمة الموقع لتحديد اتجاه القبلة',
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text(l10n?.translate('campus.settings') ?? 'الإعدادات'),
          ),
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('campus.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showPermissionRequiredDialog() {
    final l10n = context.l10n;
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        title: Text(
          l10n?.translate('campus.permission_required') ?? 'الإذن مطلوب',
        ),
        body: Text(
          l10n?.translate('campus.location_permission_required') ??
              'يحتاج التطبيق إلى إذن الموقع لتحديد اتجاه القبلة',
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: Text(l10n?.translate('campus.retry') ?? 'إعادة المحاولة'),
          ),
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: Text(
              AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء',
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    final l10n = context.l10n;
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        title: Text(
          l10n?.translate('campus.permission_denied') ?? 'تم رفض الإذن',
        ),
        body: Text(
          l10n?.translate('campus.open_app_settings') ??
              'يرجى فتح إعدادات التطبيق لمنح إذن الموقع',
        ),
        actions: [
          FButton(
            onPress: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text(l10n?.translate('campus.settings') ?? 'الإعدادات'),
          ),
          FButton(
            onPress: () => Navigator.pop(context),
            variant: FButtonVariant.outline,
            child: Text(l10n?.translate('campus.cancel') ?? 'إلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has come to the foreground, check permissions again
      _requestLocationPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    qiblaCubit.close();
    qiblaRepository.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: qiblaCubit,
      child: Scaffold(
        body: Stack(
          children: [
            // Background with Islamic pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: IslamicPatternPainter(
                    color: qiblaBaseColor,
                    gridSize: 60,
                  ),
                ),
              ),
            ),

            // Circular gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.transparent,
                      qiblaBaseColor.withValues(alpha: 0.05),
                      qiblaBaseColor.withValues(alpha: 0.1),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: BlocBuilder<QiblaCubit, QiblaState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(
                        child: state is QiblaLoading
                            ? _buildLoadingState()
                            : state is QiblaLoaded
                            ? _buildQiblaContent(context, state)
                            : state is QiblaError
                            ? _buildErrorState(context, state)
                            : _buildDefaultState(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16.0 : size.width * 0.02,
        isDesktop ? 20.0 : size.height * 0.02,
        isDesktop ? 24.0 : size.width * 0.04,
        isDesktop ? 20.0 : size.height * 0.02,
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: qiblaPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: qiblaPrimaryColor,
              iconSize: isDesktop ? 24.0 : 20.0,
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: l10n?.translate('common.close') ?? 'رجوع',
            ),
          ),
          SizedBox(width: isDesktop ? 12.0 : size.width * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('campus.qibla') ?? 'القبلة',
                  style: TextStyle(
                    fontSize: isDesktop ? 28.0 : size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                Text(
                  l10n?.translate('campus.qibla_finder') ?? 'البوصلة الإسلامية',
                  style: TextStyle(
                    fontSize: isDesktop ? 16.0 : size.width * 0.04,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          // AR camera mode (hidden on desktop / when no compass sensor).
          if (!isDesktop && qiblaRepository.isCompassAvailable) ...[
            Container(
              decoration: BoxDecoration(
                color: qiblaPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.view_in_ar_rounded),
                color: qiblaPrimaryColor,
                iconSize: isDesktop ? 24.0 : 20.0,
                onPressed: _openArMode,
                tooltip: l10n?.translate('campus.ar_mode') ?? 'وضع الكاميرا',
              ),
            ),
            SizedBox(width: isDesktop ? 12.0 : size.width * 0.02),
          ],
          Container(
            decoration: BoxDecoration(
              color: qiblaPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              color: qiblaPrimaryColor,
              iconSize: isDesktop ? 24.0 : 20.0,
              onPressed: () {
                context.read<QiblaCubit>().getQiblaDirection();
              },
              tooltip: l10n?.translate('campus.refresh') ?? 'تحديث',
            ),
          ),
        ],
      ),
    );
  }

  /// Push the AR camera screen, reusing the live [QiblaCubit] instance so the
  /// overlay shares the same heading/bearing stream.
  void _openArMode() {
    if (!qiblaRepository.isCompassAvailable) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: qiblaCubit,
          child: const QiblaArScreen(),
        ),
      ),
    );
  }

  Widget _buildQiblaContent(BuildContext context, QiblaLoaded state) {
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    // Adapt compass size based on device width but cap it for desktop
    final compassSize = isDesktop
        ? 350.0 // Fixed size for desktop
        : (size.width < 600 ? size.width * 0.75 : 450.0);
    final l10n = AppLocalizations.of(context);

    // Animations
    final compassScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    final infoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: ScaleTransition(
              scale: compassScaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Container(
                    width: compassSize + 30,
                    height: compassSize + 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: qiblaPrimaryColor.withValues(alpha: 0.1),
                        width: 5,
                      ),
                    ),
                  ),
                  Container(
                    width: compassSize + 10,
                    height: compassSize + 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: qiblaPrimaryColor.withValues(alpha: 0.2),
                        width: 5,
                      ),
                    ),
                  ),

                  // Main compass
                  SizedBox(
                    width: compassSize,
                    height: compassSize,
                    child: QiblaCompassWidget(
                      qiblaModel: state.qiblaModel,
                      isAligned: state.isAligned,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Alignment status badge
        if (state.isAligned)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.008,
            ),
            margin: EdgeInsets.only(bottom: size.height * 0.01),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60), // App theme green
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n?.translate('campus.aligned_with_qibla') ??
                      'متجه نحو القبلة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        Text(
          '${state.qiblaModel.qiblaDirection.toStringAsFixed(1)}°',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: state.isAligned ? const Color(0xFF00C853) : null,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        // Accuracy indicator
        _buildAccuracyIndicator(state, size),
        // Information cards with scroll for smaller screens
        Expanded(
          flex: 2,
          child: FadeTransition(
            opacity: infoAnimation,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - infoAnimation.value)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  children: [
                    // Direction info
                    _buildInfoCard(
                      icon: Icons.explore,
                      title: l10n?.translate('campus.direction') ?? 'الاتجاه',
                      value:
                          '${state.qiblaModel.qiblaDirection.toStringAsFixed(1)}°',
                      color: qiblaPrimaryColor,
                    ),
                    SizedBox(height: size.height * 0.02),

                    // Location info
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title:
                          l10n?.translate('campus.your_location') ??
                          'موقعك الحالي',
                      value:
                          '${state.qiblaModel.latitude.toStringAsFixed(4)}, ${state.qiblaModel.longitude.toStringAsFixed(4)}',
                      color: qiblaDarkAccentColor,
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Instructions
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                      ),
                      child: Text(
                        l10n?.translate('campus.qibla_instructions') ??
                            'قم بتوجيه الهاتف وفقًا للسهم للإشارة إلى اتجاه القبلة',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: size.width * 0.035,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyIndicator(QiblaLoaded state, Size size) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = PlatformUtils.isDesktop;

    // Calculate the angle difference
    double angleDifference =
        (state.qiblaModel.qiblaDirection - state.qiblaModel.compassDirection)
            .abs();

    // Normalize the angle to be between 0 and 180
    if (angleDifference > 180) {
      angleDifference = 360 - angleDifference;
    }

    // Calculate accuracy percentage (0° = 100%, 180° = 0%)
    double accuracy = ((180 - angleDifference) / 180 * 100).clamp(0, 100);

    // Determine color based on accuracy - using app theme colors
    Color indicatorColor;
    String accuracyText;
    IconData accuracyIcon;

    if (accuracy >= 97) {
      indicatorColor = const Color(0xFF27AE60); // App theme green
      accuracyText = l10n?.translate('campus.excellent') ?? 'ممتاز';
      accuracyIcon = Icons.stars_rounded;
    } else if (accuracy >= 85) {
      indicatorColor = const Color(0xFF16A085); // App theme teal
      accuracyText = l10n?.translate('campus.very_good') ?? 'جيد جداً';
      accuracyIcon = Icons.star_rounded;
    } else if (accuracy >= 70) {
      indicatorColor = const Color(0xFFDAA520); // App theme gold
      accuracyText = l10n?.translate('campus.good') ?? 'جيد';
      accuracyIcon = Icons.star_half_rounded;
    } else if (accuracy >= 50) {
      indicatorColor = const Color(0xFFD35400); // App theme orange
      accuracyText = l10n?.translate('campus.close') ?? 'قريب';
      accuracyIcon = Icons.navigation_rounded;
    } else {
      indicatorColor = const Color(0xFFE74C3C); // App theme red
      accuracyText = l10n?.translate('campus.searching') ?? 'ابحث';
      accuracyIcon = Icons.explore_rounded;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              accuracyIcon,
              color: indicatorColor,
              size: isDesktop ? 20.0 : size.width * 0.045,
            ),
            SizedBox(width: isDesktop ? 8.0 : size.width * 0.015),
            Text(
              accuracyText,
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 14.0 : size.width * 0.035,
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 8.0 : size.height * 0.008),
        // Accuracy progress bar - simplified
        Container(
          width: isDesktop ? 250.0 : size.width * 0.5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: accuracy / 100,
            child: Container(
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 4.0 : size.height * 0.005),
        Text(
          angleDifference < 5
              ? '${angleDifference.toStringAsFixed(1)}° ${l10n?.translate('campus.high_accuracy') ?? 'دقة عالية'}'
              : '${angleDifference.toStringAsFixed(1)}° ${l10n?.translate('campus.from_target') ?? 'من الهدف'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isDesktop ? 12.0 : size.width * 0.028,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 500.0 : double.infinity,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.0 : size.width * 0.05,
        vertical: isDesktop ? 16.0 : size.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12.0 : size.width * 0.02),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isDesktop ? 28.0 : size.width * 0.06,
            ),
          ),
          SizedBox(width: isDesktop ? 16.0 : size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 14.0 : size.width * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isDesktop ? 4.0 : size.height * 0.005),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : size.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading container
            Container(
              width: isDesktop ? 120.0 : size.width * 0.25,
              height: isDesktop ? 120.0 : size.width * 0.25,
              decoration: BoxDecoration(
                color: qiblaPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: qiblaPrimaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : size.height * 0.03),
            Text(
              l10n?.translate('campus.loading_qibla_direction') ??
                  'جاري تحديد اتجاه القبلة...',
              style: TextStyle(
                fontSize: isDesktop ? 18.0 : size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isDesktop ? 12.0 : size.height * 0.01),
            Container(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Text(
                l10n?.translate('campus.loading_qibla_direction_description') ??
                    'نقوم بتحديد موقعك وحساب اتجاه القبلة',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: size.width * 0.035,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QiblaError state) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    // Check if this is a compass sensor error
    final isCompassError =
        state.message.contains('Compass') ||
        state.message.contains('compass') ||
        state.message.contains('magnetometer') ||
        state.message.contains('sensor');

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600.0 : double.infinity,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32.0 : size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              Container(
                padding: EdgeInsets.all(isDesktop ? 40.0 : size.width * 0.08),
                decoration: BoxDecoration(
                  gradient: isCompassError
                      ? LinearGradient(
                          colors: [Colors.orange[100]!, Colors.deepOrange[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.red[100]!, Colors.red[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCompassError
                                  ? Colors.orange[200]!
                                  : Colors.red[200]!)
                              .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  isCompassError ? Icons.explore_off : Icons.error_outline,
                  size: isDesktop ? 80.0 : size.width * 0.2,
                  color: isCompassError
                      ? Colors.deepOrange[400]
                      : Colors.red[400],
                ),
              ),
              SizedBox(height: isDesktop ? 32.0 : size.height * 0.03),

              // Error title
              Text(
                isCompassError
                    ? (l10n?.translate('campus.compass_unavailable') ??
                          'البوصلة غير متاحة')
                    : (l10n?.translate('campus.error') ?? 'خطأ'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 16.0 : size.height * 0.02),

              // Error message
              Text(
                state.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 24.0 : size.height * 0.03),

              // Additional information card
              Container(
                padding: EdgeInsets.all(isDesktop ? 20.0 : size.width * 0.04),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: isDesktop ? 28.0 : 24.0,
                    ),
                    SizedBox(height: isDesktop ? 12.0 : 8.0),
                    Text(
                      isCompassError
                          ? (l10n?.translate('campus.compass_requirement') ??
                                'تتطلب هذه الميزة جهازًا مزودًا بمستشعر البوصلة (المغناطيس) والذي يتوفر عادة في الهواتف الذكية والأجهزة اللوحية فقط.')
                          : (l10n?.translate('campus.qibla_error_message') ??
                                'تأكد من تفعيل خدمة الموقع وإذن الوصول للموقع'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Show retry button only if it's not a compass error
              if (!isCompassError) ...[
                SizedBox(height: isDesktop ? 32.0 : size.height * 0.04),
                FButton(
                  onPress: () {
                    context.read<QiblaCubit>().getQiblaDirection();
                  },
                  mainAxisSize: MainAxisSize.min,
                  prefix: const Icon(Icons.refresh),
                  child: Text(
                    l10n?.translate('campus.retry') ?? 'إعادة المحاولة',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(
        l10n?.translate('campus.preparing_compass') ?? 'جاري تحضير البوصلة...',
      ),
    );
  }
}
