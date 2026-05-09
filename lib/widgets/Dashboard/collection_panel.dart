import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class CollectionsPanel extends StatelessWidget {
  const CollectionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "icon": AppStrings.iconHighReturn,
        "label": AppStrings.high_ret,
        "route": "/funds/high-return?title=High Returns"
      },
      {
        "icon": AppStrings.iconJhaveriPicks,
        "label": AppStrings.jv_picks_lbl,
        "route":"/jhaveri_all_funds?title=Jhaveri Picks"
        // No route for now
      },
      {
        "icon": AppStrings.nfo,
        "label": AppStrings.nfo_lbl,
        // No route for now
      },
      {
        "icon": AppStrings.iconLargeCap,
        "label": AppStrings.large_cap,
        "route": "/funds/large-cap?title=Large Cap"
      },
      {
        "icon": AppStrings.iconMidCap,
        "label": AppStrings.mid_cap,
        "route": "/funds/mid-cap?title=Mid Cap"
      },
      {
        "icon": AppStrings.iconSmallCap,
        "label": AppStrings.small_cap,
        "route": "/funds/small-cap?title=Small Cap"
      },
      {
        "icon": AppStrings.iconAmcs,
        "label": AppStrings.amc,
        // No route for now
      },
      {
        "icon": AppStrings.iconSectorial,
        "label": AppStrings.sectorial,
        "route": "/funds/sectorial?title=Sectorial"
      },
      {
        "icon": AppStrings.iconTaxSaver,
        "label": AppStrings.tax_sav,
        "route": "/funds/tax-saver?title=Tax Saver"
      },
    ];

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (item.containsKey("route")) {
                context.go(item["route"]!);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8F1F9),
                  child: SvgPicture.asset(
                    item["icon"]!,
                    height: 26,
                    width: 26,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item["label"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}