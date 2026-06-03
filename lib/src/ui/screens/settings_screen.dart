import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final voiceMode = ref.watch(voiceModeProvider);
    final language = ref.watch(languageProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {themeMode},
          onSelectionChanged: (value) async {
            final mode = value.first;
            ref.read(themeModeProvider.notifier).state = mode;
            await ref.read(storageProvider).setThemeMode(mode);
          },
        ),
        const SizedBox(height: 18),
        DropdownMenu<VoiceMode>(
          initialSelection: voiceMode,
          label: const Text('Voice commentary'),
          dropdownMenuEntries: const [
            DropdownMenuEntry(
              value: VoiceMode.importantOnly,
              label: 'Important events only',
            ),
            DropdownMenuEntry(
              value: VoiceMode.fullCommentary,
              label: 'Full commentary',
            ),
            DropdownMenuEntry(value: VoiceMode.off, label: 'Off'),
          ],
          onSelected: (value) async {
            if (value == null) return;
            ref.read(voiceModeProvider.notifier).state = value;
            await ref.read(storageProvider).setVoiceMode(value);
          },
        ),
        const SizedBox(height: 18),
        SegmentedButton<CommentaryLanguage>(
          segments: const [
            ButtonSegment(
              value: CommentaryLanguage.english,
              label: Text('English'),
            ),
            ButtonSegment(
              value: CommentaryLanguage.hindi,
              label: Text('Hindi'),
            ),
          ],
          selected: {language},
          onSelectionChanged: (value) async {
            final selected = value.first;
            ref.read(languageProvider.notifier).state = selected;
            await ref.read(storageProvider).setLanguage(selected);
          },
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('API failover'),
          subtitle: const Text(
            'CricketData, CricAPI, then mock data. Mock mode is enabled for reliable local builds.',
          ),
        ),
      ],
    );
  }
}
