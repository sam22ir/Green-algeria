import 'package:easy_localization/easy_localization.dart';

extension CampaignTypeExtension on String {
  String get campaignTypeLabel {
    switch (toLowerCase()) {
      case 'national':
        return 'national_type'.tr();
      case 'provincial':
        return 'provincial_type'.tr();
      case 'local':
        return 'local_type'.tr();
      default:
        return this;
    }
  }
}
