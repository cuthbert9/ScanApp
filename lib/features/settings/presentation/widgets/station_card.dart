import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../domain/models/station.dart';

/// The warehouse base this handheld is working from.
///
/// A dispatch map belongs here eventually — bays, routes, the device's own
/// position. Until that integration exists this card carries the details on
/// their own rather than a decorative stand-in, so nothing on screen implies a
/// live map that is not there.
class StationCard extends StatelessWidget {
  const StationCard({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppSpacing spacing = context.spacing;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    station.name,
                    style: context.type.headingSm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    station.coordinatesLabel,
                    style: context.type.dataSm.copyWith(
                      color: colors.dataMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            AppDetailRow(label: 'Station code', value: station.code),
            const Divider(height: 1),
            AppDetailRow(label: 'Assigned bay', value: station.bayLabel),
            const Divider(height: 1),
            AppDetailRow(
              label: 'Geofence',
              value: station.geofenceLabel,
              // Inside the fence is the normal, safe state; outside means the
              // operator has walked away from the bay they are loading.
              accent: station.insideGeofence
                  ? StatAccent.success
                  : StatAccent.warning,
            ),
          ],
        ),
      ),
    );
  }
}
