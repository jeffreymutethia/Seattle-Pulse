import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/reaction_popup.dart';

final List<Reaction> kReactions = [
  Reaction(
    name: "like",
    emoji: "👍",
    color: Colors.blue,
    label: "Like",
  ),
  Reaction(
    name: "love",
    emoji: "❤️",
    color: Colors.red,
    label: "Love",
  ),
  Reaction(
    name: "haha",
    emoji: "😄",
    color: Colors.yellow.shade700,
    label: "Haha",
  ),
  Reaction(
    name: "wow",
    emoji: "😲",
    color: Colors.green,
    label: "Wow",
  ),
  Reaction(
    name: "sad",
    emoji: "😢",
    color: Colors.purple,
    label: "Sad",
  ),
  Reaction(
    name: "angry",
    emoji: "😡",
    color: Colors.orange,
    label: "Angry",
  ),
];
