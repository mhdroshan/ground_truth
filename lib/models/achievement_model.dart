import 'package:flutter/material.dart';

enum AchievementCategory {
  reporting('Reporting', Icons.edit_note_rounded),
  verification('Verification', Icons.verified_user_rounded),
  tagging('Tag Pioneer', Icons.tag_rounded),
  community('Community', Icons.forum_rounded),
  mastery('Sentinel Mastery', Icons.military_tech_rounded);

  final String label;
  final IconData icon;
  const AchievementCategory(this.label, this.icon);
}

enum AchievementTier {
  bronze('Bronze', Color(0xFFCD7F32), Color(0xFFFFF3E0)),
  silver('Silver', Color(0xFF9E9E9E), Color(0xFFF5F5F5)),
  gold('Gold', Color(0xFFFFB300), Color(0xFFFFF8E1)),
  diamond('Diamond', Color(0xFF00ACC1), Color(0xFFE0F7FA));

  final String label;
  final Color primaryColor;
  final Color badgeBackgroundColor;
  const AchievementTier(this.label, this.primaryColor, this.badgeBackgroundColor);
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final IconData icon;
  final int currentProgress;
  final int maxProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String howToEarn;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.icon,
    required this.currentProgress,
    required this.maxProgress,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.xpReward,
    required this.howToEarn,
  });

  double get progressFraction =>
      maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progressFraction * 100).round();

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    AchievementCategory? category,
    AchievementTier? tier,
    IconData? icon,
    int? currentProgress,
    int? maxProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    String? howToEarn,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tier: tier ?? this.tier,
      icon: icon ?? this.icon,
      currentProgress: currentProgress ?? this.currentProgress,
      maxProgress: maxProgress ?? this.maxProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      howToEarn: howToEarn ?? this.howToEarn,
    );
  }
}
