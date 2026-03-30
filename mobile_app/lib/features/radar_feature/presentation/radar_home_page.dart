import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/services/route_history_service.dart';
import '../../../app/global/global_error_bus.dart';
import '../engine/services/geofencing_service.dart';
import 'bloc/radar_bloc.dart';
import 'map/radar_map_page.dart';
import 'map/radar_map_style.dart';

class RadarHomePage extends StatefulWidget {
  const RadarHomePage({super.key});

  @override
  State<RadarHomePage> createState() => _RadarHomePageState();
}

class _RadarHomePageState extends State<RadarHomePage> {
  static const _fallbackRoute = RouteSelection(
    fromDistrict: 'Kocaeli, İzmit',
    toDistrict: 'İzmir, Aliağa',
  );

  RouteSelection _activeRoute = _fallbackRoute;
  List<RouteSelection> _recentRoutes = const [];

  List<_CityOption> _cities = const [];
  List<_DistrictOption> _fromDistricts = const [];
  List<_DistrictOption> _toDistricts = const [];

  _CityOption? _fromCity;
  _CityOption? _toCity;
  _DistrictOption? _fromDistrict;
  _DistrictOption? _toDistrict;

  bool _isFormLoading = true;
  bool _isRoutePanelExpanded = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeFormAndFetch());
  }

  Future<void> _initializeFormAndFetch() async {
    final historyService = serviceLocator<RouteHistoryService>();
    final recent = await historyService.getRecentRoutes();
    final initialRoute = recent.isNotEmpty ? recent.first : _fallbackRoute;

    final cities = await _fetchCities();
    if (cities.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isFormLoading = false;
        _recentRoutes = recent;
      });
      serviceLocator<GlobalErrorBus>().error('İl listesi alınamadı. Lütfen tekrar deneyin.');
      return;
    }

    _CityOption pickCity(String routeText, String fallbackName) {
      final cityHint = _extractCityHint(routeText);
      if (cityHint != null) {
        final match = _findCityByName(cities, cityHint);
        if (match != null) return match;
      }

      final fallback = _findCityByName(cities, fallbackName);
      if (fallback != null) return fallback;
      return cities.first;
    }

    final selectedFromCity = pickCity(initialRoute.fromDistrict, 'Kocaeli');
    final selectedToCity = pickCity(initialRoute.toDistrict, 'İzmir');

    final fromDistricts = await _fetchDistricts(selectedFromCity.id);
    final toDistricts = await _fetchDistricts(selectedToCity.id);

    _DistrictOption? pickDistrict(
      List<_DistrictOption> options,
      String routeText,
      String fallbackName,
    ) {
      final districtHint = _extractDistrictHint(routeText);
      final byHint = _findDistrictByName(options, districtHint);
      if (byHint != null) return byHint;

      final byFallback = _findDistrictByName(options, fallbackName);
      if (byFallback != null) return byFallback;

      if (options.isEmpty) return null;
      return options.first;
    }

    final selectedFromDistrict = pickDistrict(fromDistricts, initialRoute.fromDistrict, 'İzmit');
    final selectedToDistrict = pickDistrict(toDistricts, initialRoute.toDistrict, 'Aliağa');

    if (!mounted) return;

    setState(() {
      _cities = cities;
      _recentRoutes = recent;
      _fromCity = selectedFromCity;
      _toCity = selectedToCity;
      _fromDistricts = fromDistricts;
      _toDistricts = toDistricts;
      _fromDistrict = selectedFromDistrict;
      _toDistrict = selectedToDistrict;
      _activeRoute = _buildCurrentRouteSelection() ?? initialRoute;
      _isFormLoading = false;
    });

    final route = _buildCurrentRouteSelection();
    if (route != null) {
      _dispatchRoute(route, forceRefresh: false);
    }
  }

  Future<List<_CityOption>> _fetchCities() async {
    final dio = serviceLocator<Dio>();
    final response = await dio.get<Map<String, dynamic>>('/api/cities');
    final raw = response.data?['data'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => _CityOption(
            id: (item['id'] ?? item['Id']).toString(),
            name: (item['name'] ?? item['Name']).toString(),
          ),
        )
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<_DistrictOption>> _fetchDistricts(String cityId) async {
    final dio = serviceLocator<Dio>();
    final response = await dio.get<Map<String, dynamic>>(
      '/api/districts',
      queryParameters: {'cityId': cityId},
    );
    final raw = response.data?['data'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => _DistrictOption(
            id: (item['id'] ?? item['Id']).toString(),
            name: (item['name'] ?? item['Name']).toString(),
          ),
        )
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);
  }

  String _normalizeTr(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  String? _extractCityHint(String input) {
    final parts = input.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (parts.length >= 2) return parts.first;
    return null;
  }

  String _extractDistrictHint(String input) {
    final parts = input.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (parts.length >= 2) return parts.sublist(1).join(', ');
    return input.trim();
  }

  _CityOption? _findCityByName(List<_CityOption> cities, String name) {
    final needle = _normalizeTr(name);
    for (final city in cities) {
      if (_normalizeTr(city.name) == needle) return city;
    }
    return null;
  }

  _DistrictOption? _findDistrictByName(List<_DistrictOption> districts, String name) {
    final needle = _normalizeTr(name);
    for (final district in districts) {
      if (_normalizeTr(district.name) == needle) return district;
    }
    return null;
  }

  RouteSelection? _buildCurrentRouteSelection() {
    if (_fromCity == null || _toCity == null || _fromDistrict == null || _toDistrict == null) {
      return null;
    }

    return RouteSelection(
      fromDistrict: '${_fromCity!.name}, ${_fromDistrict!.name}',
      toDistrict: '${_toCity!.name}, ${_toDistrict!.name}',
    );
  }

  Future<void> _onFromCityChanged(_CityOption? city) async {
    if (city == null) return;
    setState(() {
      _fromCity = city;
      _fromDistricts = const [];
      _fromDistrict = null;
      _isFormLoading = true;
    });

    try {
      final districts = await _fetchDistricts(city.id);
      if (!mounted) return;
      setState(() {
        _fromDistricts = districts;
        _fromDistrict = districts.isNotEmpty ? districts.first : null;
      });
    } catch (_) {
      serviceLocator<GlobalErrorBus>().error('Başlangıç ilçe listesi alınamadı.');
    } finally {
      if (mounted) {
        setState(() => _isFormLoading = false);
      }
    }
  }

  Future<void> _onToCityChanged(_CityOption? city) async {
    if (city == null) return;
    setState(() {
      _toCity = city;
      _toDistricts = const [];
      _toDistrict = null;
      _isFormLoading = true;
    });

    try {
      final districts = await _fetchDistricts(city.id);
      if (!mounted) return;
      setState(() {
        _toDistricts = districts;
        _toDistrict = districts.isNotEmpty ? districts.first : null;
      });
    } catch (_) {
      serviceLocator<GlobalErrorBus>().error('Varış ilçe listesi alınamadı.');
    } finally {
      if (mounted) {
        setState(() => _isFormLoading = false);
      }
    }
  }

  Future<void> _applyRouteToForm(RouteSelection route) async {
    final fromCityHint = _extractCityHint(route.fromDistrict);
    final toCityHint = _extractCityHint(route.toDistrict);

    if (_cities.isEmpty) return;

    final nextFromCity = fromCityHint != null ? _findCityByName(_cities, fromCityHint) : null;
    final nextToCity = toCityHint != null ? _findCityByName(_cities, toCityHint) : null;

    final fromCity = nextFromCity ?? _fromCity;
    final toCity = nextToCity ?? _toCity;
    if (fromCity == null || toCity == null) return;

    setState(() => _isFormLoading = true);

    final fromDistricts = await _fetchDistricts(fromCity.id);
    final toDistricts = await _fetchDistricts(toCity.id);

    final fromDistrict = _findDistrictByName(fromDistricts, _extractDistrictHint(route.fromDistrict));
    final toDistrict = _findDistrictByName(toDistricts, _extractDistrictHint(route.toDistrict));

    if (!mounted) return;

    setState(() {
      _fromCity = fromCity;
      _toCity = toCity;
      _fromDistricts = fromDistricts;
      _toDistricts = toDistricts;
      _fromDistrict = fromDistrict ?? (fromDistricts.isNotEmpty ? fromDistricts.first : null);
      _toDistrict = toDistrict ?? (toDistricts.isNotEmpty ? toDistricts.first : null);
      _isFormLoading = false;
    });
  }

  Future<void> _onSubmitRoute() async {
    final route = _buildCurrentRouteSelection();

    if (route == null) {
      serviceLocator<GlobalErrorBus>().warning('Lütfen başlangıç/varış il ve ilçelerini seçin.');
      return;
    }

    await serviceLocator<RouteHistoryService>().saveRoute(route);
    final recent = await serviceLocator<RouteHistoryService>().getRecentRoutes();

    if (mounted) {
      setState(() {
        _recentRoutes = recent;
        _activeRoute = route;
      });
    }

    _dispatchRoute(route, forceRefresh: true);
  }

  void _dispatchRoute(RouteSelection route, {required bool forceRefresh}) {
    context.read<RadarBloc>().add(
          RadarRequested(
            fromDistrict: route.fromDistrict,
            toDistrict: route.toDistrict,
            forceRefresh: forceRefresh,
          ),
        );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RadarBloc, RadarState>(
      listener: (context, state) {
        if (state.status == RadarLoadStatus.failure && state.failure != null) {
          serviceLocator<GlobalErrorBus>().error(state.failure!.message);
          return;
        }

        if (state.status == RadarLoadStatus.success) {
          serviceLocator<GeofencingService>().syncTrackedRadars(state.data.radars);
          if (_isRoutePanelExpanded) {
            setState(() => _isRoutePanelExpanded = false);
          }
        }
      },
      builder: (context, state) {
        if (state.status == RadarLoadStatus.loading &&
            state.data.radars.isEmpty &&
            state.data.speedTunnels.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        return Stack(
          children: [
            RadarMapPage(
              stylePreset: RadarMapStylePreset.night,
              radars: state.data.radars,
              speedTunnels: state.data.speedTunnels,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 14, right: 14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      color: const Color(0xCC111827),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.alt_route_rounded, color: Color(0xFF93C5FD)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Rota Seçimi',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _isRoutePanelExpanded = !_isRoutePanelExpanded);
                                  },
                                  icon: Icon(
                                    _isRoutePanelExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    context.read<RadarBloc>().add(
                                          RadarRefreshed(
                                            fromDistrict: _activeRoute.fromDistrict,
                                            toDistrict: _activeRoute.toDistrict,
                                          ),
                                        );
                                  },
                                  icon: const Icon(Icons.refresh, color: Color(0xFFCBD5E1)),
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              firstChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<_CityOption>(
                                    value: _fromCity,
                                    decoration: const InputDecoration(labelText: 'Nereden - İl'),
                                    isExpanded: true,
                                    items: _cities
                                        .map(
                                          (city) => DropdownMenuItem(
                                            value: city,
                                            child: Text(city.name),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: _isFormLoading ? null : _onFromCityChanged,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<_DistrictOption>(
                                    value: _fromDistrict,
                                    decoration: const InputDecoration(labelText: 'Nereden - İlçe'),
                                    isExpanded: true,
                                    items: _fromDistricts
                                        .map(
                                          (district) => DropdownMenuItem(
                                            value: district,
                                            child: Text(district.name),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: _isFormLoading
                                        ? null
                                        : (value) {
                                            setState(() => _fromDistrict = value);
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<_CityOption>(
                                    value: _toCity,
                                    decoration: const InputDecoration(labelText: 'Nereye - İl'),
                                    isExpanded: true,
                                    items: _cities
                                        .map(
                                          (city) => DropdownMenuItem(
                                            value: city,
                                            child: Text(city.name),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: _isFormLoading ? null : _onToCityChanged,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<_DistrictOption>(
                                    value: _toDistrict,
                                    decoration: const InputDecoration(labelText: 'Nereye - İlçe'),
                                    isExpanded: true,
                                    items: _toDistricts
                                        .map(
                                          (district) => DropdownMenuItem(
                                            value: district,
                                            child: Text(district.name),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: _isFormLoading
                                        ? null
                                        : (value) {
                                            setState(() => _toDistrict = value);
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _isFormLoading ? null : _onSubmitRoute,
                                          icon: const Icon(Icons.radar_rounded),
                                          label: const Text('Radarı Getir'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 6, bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.route_rounded, color: Color(0xFF93C5FD), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_activeRoute.fromDistrict} → ${_activeRoute.toDistrict}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildCountBadge(
                                      label: '${state.data.speedTunnels.length} Koridor',
                                      color: const Color(0xFF0EA5E9),
                                      onTap: () => setState(() => _isRoutePanelExpanded = true),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildCountBadge(
                                      label: '${state.data.radars.length} Radar',
                                      color: const Color(0xFFFB7185),
                                      onTap: () => setState(() => _isRoutePanelExpanded = true),
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _isRoutePanelExpanded
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 220),
                            ),
                            const SizedBox(height: 8),
                            _buildResultHint(context, state),
                            if (_recentRoutes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _recentRoutes
                                    .map(
                                      (item) => ActionChip(
                                        label: Text('${item.fromDistrict} → ${item.toDistrict}'),
                                        onPressed: () async {
                                          await _applyRouteToForm(item);
                                          if (!mounted) return;
                                          final route = _buildCurrentRouteSelection();
                                          if (route == null) return;
                                          setState(() => _activeRoute = route);
                                          _dispatchRoute(route, forceRefresh: true);
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await serviceLocator<RouteHistoryService>().clearRoutes();
                                    if (!mounted) return;
                                    setState(() => _recentRoutes = const []);
                                  },
                                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                                  label: const Text('Eski aramaları temizle'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultHint(BuildContext context, RadarState state) {
    if (state.status == RadarLoadStatus.loading) {
      return Row(
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Rota verisi alınıyor...', style: TextStyle(color: Color(0xFFCBD5E1))),
        ],
      );
    }

    if (state.status == RadarLoadStatus.success) {
      final tunnelCount = state.data.speedTunnels.length;
      final radarCount = state.data.radars.length;
      return Text(
        'Sonuç: $tunnelCount hız koridoru, $radarCount radar noktası',
        style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w600),
      );
    }

    if (state.status == RadarLoadStatus.failure && state.failure != null) {
      return Text(
        'Hata: ${state.failure!.message}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.w600),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCountBadge({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: badge,
    );
  }
}

class _CityOption {
  const _CityOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _DistrictOption {
  const _DistrictOption({required this.id, required this.name});

  final String id;
  final String name;
}
