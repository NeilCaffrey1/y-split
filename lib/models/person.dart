import 'package:flutter/material.dart';

class Person {
  String name;
  Color color;

  Person({
    required this.name,
    required this.color,
  });

  /// Generate a color for a person based on their index
  static Color generateColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
    ];
    return colors[index % colors.length];
  }

  /// Create a person with auto-generated color
  factory Person.withAutoColor(String name, int index) {
    return Person(
      name: name,
      color: generateColor(index),
    );
  }

  @override
  String toString() {
    return 'Person(name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}