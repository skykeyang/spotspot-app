import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bingo.dart';

// Pickleball pool — mirrors the web app's pickleballPool
// 40 events across 6 categories

final List<Map<String, dynamic>> _pickleballEvents = [
  // COURT LIFE
  {'text': 'Open play session at the courts', 'category': 'COURT LIFE', 'difficulty': 1, 'active': true},
  {'text': 'Dink rally goes 10+ shots', 'category': 'COURT LIFE', 'difficulty': 1, 'active': true},
  {'text': 'Kitchen line dispute with your partner', 'category': 'COURT LIFE', 'difficulty': 2, 'active': true},
  {'text': 'Wait longer than 30 min for a court', 'category': 'COURT LIFE', 'difficulty': 1, 'active': true},
  {'text': "Someone calls 'mine!' too late", 'category': 'COURT LIFE', 'difficulty': 1, 'active': true},
  {'text': 'Stack on a doubles team', 'category': 'COURT LIFE', 'difficulty': 2, 'active': true},
  {'text': 'Court split — two on, two waiting', 'category': 'COURT LIFE', 'difficulty': 1, 'active': true},

  // GEAR
  {'text': 'Someone shows up barefoot', 'category': 'GEAR', 'difficulty': 2, 'active': true},
  {'text': 'Brand new paddle unboxing at the courts', 'category': 'GEAR', 'difficulty': 1, 'active': true},
  {'text': 'Matching partner outfits spotted', 'category': 'GEAR', 'difficulty': 2, 'active': true},
  {'text': 'Paddle tape or edge guard peeling', 'category': 'GEAR', 'difficulty': 1, 'active': true},
  {'text': 'Overgrip looking grimy and unwrapped', 'category': 'GEAR', 'difficulty': 1, 'active': true},
  {'text': 'Someone playing in running shoes', 'category': 'GEAR', 'difficulty': 1, 'active': true},
  {'text': 'Court shoes with zero tread left', 'category': 'GEAR', 'difficulty': 2, 'active': true},
  {'text': "Paddle comparison chat — 'what's yours?'", 'category': 'GEAR', 'difficulty': 1, 'active': true},

  // THE PEOPLE
  {'text': 'Pickleball dad energy — hat, sleeves, intensity', 'category': 'THE PEOPLE', 'difficulty': 1, 'active': true},
  {'text': 'Beginner asks if they can serve overhand', 'category': 'THE PEOPLE', 'difficulty': 1, 'active': true},
  {'text': 'Someone coaches unprompted from the sideline', 'category': 'THE PEOPLE', 'difficulty': 2, 'active': true},
  {'text': 'Trash talk between friends across the net', 'category': 'THE PEOPLE', 'difficulty': 1, 'active': true},
  {'text': "Someone refuses to play with beginners", 'category': 'THE PEOPLE', 'difficulty': 2, 'active': true},
  {'text': "Auntie who's been playing 10 years and still wins", 'category': 'THE PEOPLE', 'difficulty': 1, 'active': true},

  // THE DRAMA
  {'text': 'Erne attempt — made or missed', 'category': 'THE DRAMA', 'difficulty': 3, 'active': true},
  {'text': 'Around-the-post (ATP) winner', 'category': 'THE DRAMA', 'difficulty': 3, 'active': true},
  {'text': 'Pop-up smash to the face (accidental)', 'category': 'THE DRAMA', 'difficulty': 2, 'active': true},
  {'text': "Net cord winner — 'sorry!'", 'category': 'THE DRAMA', 'difficulty': 1, 'active': true},
  {'text': 'Third-shot drop lands perfectly in kitchen', 'category': 'THE DRAMA', 'difficulty': 2, 'active': true},
  {'text': 'Argument about whether it was in or out', 'category': 'THE DRAMA', 'difficulty': 1, 'active': true},
  {'text': 'Score disagreement goes to 30 seconds', 'category': 'THE DRAMA', 'difficulty': 1, 'active': true},
  {'text': "Someone calls 'two' when it's 'three'", 'category': 'THE DRAMA', 'difficulty': 1, 'active': true},

  // POST-MATCH
  {'text': "'Good game' paddle tap line", 'category': 'POST-MATCH', 'difficulty': 1, 'active': true},
  {'text': 'Post-match kopi or food run', 'category': 'POST-MATCH', 'difficulty': 1, 'active': true},
  {'text': 'Someone immediately re-paddles for next game', 'category': 'POST-MATCH', 'difficulty': 1, 'active': true},
  {'text': 'Post-match court recap goes 5+ minutes', 'category': 'POST-MATCH', 'difficulty': 1, 'active': true},
  {'text': "'Same group next week?' planning", 'category': 'POST-MATCH', 'difficulty': 1, 'active': true},

  // SINGAPORE SPECIFIC
  {'text': 'Playing at Kallang or Serangoon courts', 'category': 'SG PICKLE', 'difficulty': 1, 'active': true},
  {'text': 'Someone mentions wanting indoor courts', 'category': 'SG PICKLE', 'difficulty': 1, 'active': true},
  {'text': 'Rain interrupts outdoor play', 'category': 'SG PICKLE', 'difficulty': 1, 'active': true},
  {'text': 'Booking a court via ActiveSG app', 'category': 'SG PICKLE', 'difficulty': 2, 'active': true},
  {'text': "Someone asks 'what's your DUPR?'", 'category': 'SG PICKLE', 'difficulty': 2, 'active': true},
];

final List<Map<String, dynamic>> _sgLifeEvents = [
  {'text': 'Tissue packet chopes a table', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Hawker tray photo happens', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Queue longer than 15 minutes for hawker food', 'category': 'HAWKER', 'difficulty': 2, 'active': true},
  {'text': 'Someone orders chicken rice with extra chilli', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Nasi lemak wrapped in brown paper spotted', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Kopi/C order happens perfectly in dialect', 'category': 'HAWKER', 'difficulty': 2, 'active': true},
  {'text': 'Someone mixes all the sauces at the condiment station', 'category': 'HAWKER', 'difficulty': 2, 'active': true},
  {'text': 'Roti prata order comes out wrong shape', 'category': 'HAWKER', 'difficulty': 2, 'active': true},
  {'text': 'Someone brings a Tupperware to a restaurant', 'category': 'HAWKER', 'difficulty': 2, 'active': true},
  {'text': 'Roti john spotted at a hawker stall', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Ice kacang or chendol order spotted', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Hawker centre ceiling fan spotted', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Plastic bag tied to chair to chope', 'category': 'HAWKER', 'difficulty': 1, 'active': true},
  {'text': 'Latte art photo before first sip', 'category': 'CAFÉ', 'difficulty': 1, 'active': true},
  {'text': 'Cafe looks better than the food', 'category': 'CAFÉ', 'difficulty': 2, 'active': true},
  {'text': 'Someone changes seats for better lighting', 'category': 'CAFÉ', 'difficulty': 1, 'active': true},
  {'text': 'MRT door closes on someone rushing', 'category': 'TRANSPORT', 'difficulty': 1, 'active': true},
  {'text': 'Priority seat debate', 'category': 'TRANSPORT', 'difficulty': 2, 'active': true},
  {'text': "Someone's bag on the seat during peak hour", 'category': 'TRANSPORT', 'difficulty': 1, 'active': true},
  {'text': 'Tissues or umbrella on bus seat', 'category': 'TRANSPORT', 'difficulty': 1, 'active': true},
  {'text': 'Someone asleep standing up on the MRT', 'category': 'TRANSPORT', 'difficulty': 1, 'active': true},
  {'text': 'ERP gantry photo or mention', 'category': 'DRIVING', 'difficulty': 1, 'active': true},
  {'text': 'Someone complains about COE prices', 'category': 'DRIVING', 'difficulty': 1, 'active': true},
  {'text': 'Road rage or horn honking within earshot', 'category': 'DRIVING', 'difficulty': 1, 'active': true},
];

List<BingoEvent> _toBingoEvents(List<Map<String, dynamic>> raw) {
  return raw.map((e) => BingoEvent.fromJson(e)).toList();
}

final BingoPool sgLifePool = BingoPool(
  id: 'sg-life-2026-w16',
  name: 'SG Life',
  description: 'The everyday SG experience',
  color: '#D94141',
  startDate: '2026-04-14',
  endDate: '2027-12-31',
  type: 'featured',
  emoji: '🇸🇬',
  tagline: "This week's board",
  active: true,
  events: _toBingoEvents(_sgLifeEvents),
);

final BingoPool pickleballPool = BingoPool(
  id: 'pickleball-2026',
  name: 'Pickleball',
  description: 'Spot the pickleball life — dinks, dops, and drama',
  color: '#0EA5E9',
  startDate: '2026-11-24',
  endDate: '2027-12-31',
  type: 'alternate',
  emoji: '🎾',
  tagline: 'Dink Responsibly',
  active: true,
  events: _toBingoEvents(_pickleballEvents),
);

final List<BingoPool> allPools = [sgLifePool, pickleballPool];
final List<BingoPool> activePools = allPools.where((p) => p.active).toList();

BingoPool? getPoolById(String id) {
  try { return allPools.firstWhere((p) => p.id == id); }
  catch (_) { return null; }
}

List<BingoEvent> shuffleAndPick(List<BingoEvent> arr, int count) {
  final shuffled = List<BingoEvent>.from(arr)..shuffle(Random());
  return shuffled.take(count).toList();
}

List<BingoEvent> generateBoardEvents(String poolId) {
  final pool = getPoolById(poolId);
  if (pool == null) return [];
  final activeEvents = pool.events.where((e) => e.active).toList();
  return shuffleAndPick(activeEvents, 24);
}

Color hexToColor(String hex) {
  final hexClean = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexClean', radix: 16));
}