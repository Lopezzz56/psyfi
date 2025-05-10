import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class CalmingAudioScreen extends StatefulWidget {
  const CalmingAudioScreen({super.key});

  @override
  State<CalmingAudioScreen> createState() => _CalmingAudioScreenState();
}

class _CalmingAudioScreenState extends State<CalmingAudioScreen> {
  late AudioPlayer _player;

  final List<Map<String, String>> _audios = [
    {
      'title': 'Ocean Waves',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    },
    {
      'title': 'Rain and Thunder',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      'image': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
    },
    {
      'title': 'Forest Ambience',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'image': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _setAudio(_audios[_currentIndex]['url']!);
  }

  Future<void> _setAudio(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  void _playNext() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _audios.length;
    });
    _setAudio(_audios[_currentIndex]['url']!);
  }

  void _playPrevious() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _audios.length) % _audios.length;
    });
    _setAudio(_audios[_currentIndex]['url']!);
  }
Stream<DurationState> get _durationStateStream =>
    Rx.combineLatest2<Duration, Duration?, DurationState>(
      _player.positionStream,
      _player.durationStream,
      (position, duration) =>
          DurationState(position: position, total: duration ?? Duration.zero),
    );

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = _audios[_currentIndex];

    return Scaffold(
            backgroundColor: Colors.white,

        appBar: AppBar(
        backgroundColor: Colors.white,
        
        title: Text(
          'Calming Audio Info',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
     body: Column(
  children: [
    // Image
    Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(currentAudio['image']!),
          fit: BoxFit.cover,
        ),
      ),
    ),

    // Title
    Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        currentAudio['title']!,
          style: GoogleFonts.cormorantGaramond(
             fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
      ),
    ),

    // Slider
    StreamBuilder<DurationState>(
      stream: _durationStateStream,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final position = durationState?.position ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Slider(
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.blueAccent.withOpacity(0.3),
            min: 0.0,
            max: total.inMilliseconds.toDouble(),
            value: position.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        );
      },
    ),

    const SizedBox(height: 20),

    // Controls
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.blueAccent),
            iconSize: 60,
            onPressed: _playPrevious,
          ),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.blueAccent,
                ),
                iconSize: 80,
                onPressed: () {
                  isPlaying ? _player.pause() : _player.play();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.blueAccent),
            iconSize: 60,
            onPressed: _playNext,
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
  ],
),

    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class DurationState {
  final Duration position;
  final Duration total;

  DurationState({required this.position, required this.total});
}
