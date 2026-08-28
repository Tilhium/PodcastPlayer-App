// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayerButtons extends StatelessWidget {
  const PlayerButtons({
    Key? key,
    required this.audioPlayer,
  }) : super(key: key);

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 45,
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white,
          ),
          onPressed: () {
            final newPosition =
                audioPlayer.position - const Duration(seconds: 10); 
            audioPlayer.seek(newPosition);
          },
        ),
        StreamBuilder<PlayerState>( 
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) { 
              final playerState = snapshot.data!; 
              final processingState = playerState.processingState;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) { 
                return Container( 
                  width: 64.0,
                  height: 64.0,
                  margin: const EdgeInsets.all(10.0),
                  child: const CircularProgressIndicator(),
                );
              } else if (!audioPlayer.playing) { 
                return IconButton( 
                  onPressed: audioPlayer.play,
                  iconSize: 75,
                  icon: const Icon(
                    Icons.play_circle,
                    color: Colors.white,
                  ),
                );
              } else if (processingState != ProcessingState.completed) {
                return IconButton( 
                  icon: const Icon(
                    Icons.pause_circle, 
                    color: Colors.white,
                  ),
                  iconSize: 75.0,
                  onPressed: audioPlayer.pause,
                );
              } else { 
                return IconButton(
                  icon: const Icon(
                    Icons.replay_circle_filled_outlined,
                    color: Colors.white,
                  ),
                  iconSize: 75.0,
                  onPressed: () => audioPlayer.seek(
                    Duration.zero,
                    index: audioPlayer.effectiveIndices!.first,
                  ),
                );
              }
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
        IconButton(
          iconSize: 45,
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white,
          ),
          onPressed: () {
            final newPosition =
                audioPlayer.position + const Duration(seconds: 10);
            audioPlayer.seek(newPosition);
          },
        ),
      ],
    );
  }
}
