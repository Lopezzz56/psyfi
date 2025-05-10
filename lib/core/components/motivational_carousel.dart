import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';  // Only import this one if you're using carousel_slider

class MotivationalCarousel extends StatelessWidget {
  const MotivationalCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> quotes = [
      "Believe you can and you're halfway there.",
      "Your mind is a powerful thing. Fill it with positivity.",
      "Every day may not be good, but there's something good in every day.",
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
        aspectRatio: 16/9,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      items: quotes.map((quote) {
        return Builder(
          builder: (BuildContext context) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    quote,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}