import 'dart:math';

/// Local campaign cover images — Phase 3 (11 covers)
/// Used as fallback when a campaign has no coverImageAsset set in the database.
class AppCampaignCovers {
  static const List<String> list = [
    'assets/images/campaigns/campaign_national_planting.png',
    'assets/images/campaigns/campaign_forest_restoration.png',
    'assets/images/campaigns/campaign_provincial_green.png',
    'assets/images/campaigns/campaign_youth_schools.png',
    'assets/images/campaigns/campaign_sahara_edge.png',
    'assets/images/campaigns/campaign_coastal_planting.png',
    'assets/images/campaigns/campaign_sahara_green.png',
    'assets/images/campaigns/campaign_urban_greening.png',
    'assets/images/campaigns/campaign_mountains_reforestation.png',
    'assets/images/campaigns/campaign_desert_oasis.png',
    'assets/images/campaigns/campaign_urban_schools.png',
  ];

  static const List<String> _national = [
    'assets/images/campaigns/campaign_national_planting.png',
    'assets/images/campaigns/campaign_coastal_planting.png',
    'assets/images/campaigns/campaign_urban_greening.png',
    'assets/images/campaigns/campaign_mountains_reforestation.png',
  ];

  static const List<String> _provincial = [
    'assets/images/campaigns/campaign_provincial_green.png',
    'assets/images/campaigns/campaign_forest_restoration.png',
    'assets/images/campaigns/campaign_sahara_green.png',
    'assets/images/campaigns/campaign_urban_schools.png',
  ];

  static const List<String> _local = [
    'assets/images/campaigns/campaign_youth_schools.png',
    'assets/images/campaigns/campaign_sahara_edge.png',
    'assets/images/campaigns/campaign_urban_greening.png',
    'assets/images/campaigns/campaign_desert_oasis.png',
  ];

  /// Returns a random cover based on campaign type for variety.
  static String forType(String? type) {
    final r = Random();
    switch (type?.toLowerCase()) {
      case 'national':
        return _national[r.nextInt(_national.length)];
      case 'provincial':
        return _provincial[r.nextInt(_provincial.length)];
      case 'local':
        return _local[r.nextInt(_local.length)];
      default:
        return list[r.nextInt(list.length)];
    }
  }
}
