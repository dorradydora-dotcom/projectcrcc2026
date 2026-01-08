import 'package:amiraly/E-commerce_project/features/auth/homepage/homepagecontroller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';

/// بناء عناصر شريط التنقل
List<CurvedNavigationBarItem> buildNavigationItems(
  HomePageController controller,
  AnimationController animationController,
  Animation<double> glowAnimation,
  Animation<double> scaleAnimation,
) {
  const labels = ['الرئيسية', 'المناطق', 'المفضلة', 'محطات', 'احمال'];
  const icons = [
    Icons.home_outlined,
    Icons.account_tree_outlined,
    Icons.favorite_border_outlined,
    Icons.workspaces_outlined,
    Icons.bolt_outlined,
  ];

  return List.generate(5, (index) {
    final isSelected = controller.selectedPage.value == index;
    final glowColor = glowColors[index];

    return CurvedNavigationBarItem(
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) => Transform.scale(
          scale: isSelected ? scaleAnimation.value : 0.9,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? glowColor : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: glowColor.withOpacity(glowAnimation.value),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icons[index], color: C.white, size: 24),
          ),
        ),
      ),
      label: labels[index],
      labelStyle: TextStyle(
        fontSize: 12,
        fontFamily: Appfontstring.ChangaLight,
        color: C.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  });
}
