/// Le champ de saisie partagé, sur son comportement multiligne.
///
/// Ce qui est vérifié ici n'est pas cosmétique : un champ de description qui
/// n'accepte qu'une ligne, ou dont la touche Entrée valide le formulaire au
/// lieu d'aller à la ligne, empêche purement et simplement d'écrire un
/// paragraphe.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ablony/shared/widgets/input.dart';

/// Monte le champ seul et renvoie le `TextField` que Flutter a réellement
/// construit — c'est lui qui porte le comportement, pas nos paramètres.
Future<TextField> _champ(WidgetTester tester, Input input) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: input)),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

void main() {
  group('Input multiligne', () {
    testWidgets('par défaut : une seule ligne, Entrée ne va pas à la ligne',
        (tester) async {
      final champ = await _champ(tester, const Input(label: 'Nom'));

      expect(champ.maxLines, 1);
      expect(champ.keyboardType, TextInputType.text);
      expect(champ.textInputAction, isNot(TextInputAction.newline));
    });

    testWidgets('maxLines > 1 : clavier multiligne et Entrée va à la ligne',
        (tester) async {
      final champ = await _champ(tester, const Input(maxLines: 5));

      expect(champ.maxLines, 5);
      // Sans cela, le clavier mobile affiche « OK » au lieu du retour chariot.
      expect(champ.keyboardType, TextInputType.multiline);
      expect(champ.textInputAction, TextInputAction.newline);
    });

    testWidgets('InputType.multiline donne un champ sans limite de lignes',
        (tester) async {
      final champ = await _champ(tester, const Input(type: InputType.multiline));

      // `maxLines` valant 1 par défaut, ce cas ne fonctionnait pas.
      expect(champ.maxLines, isNull);
      expect(champ.keyboardType, TextInputType.multiline);
      expect(champ.textInputAction, TextInputAction.newline);
    });

    testWidgets('minLines ouvre le champ déjà haut', (tester) async {
      final champ = await _champ(
        tester,
        const Input(minLines: 4, maxLines: 10),
      );

      expect(champ.minLines, 4);
      expect(champ.maxLines, 10);
    });

    testWidgets('un mot de passe reste sur une ligne', (tester) async {
      // Flutter interdit d'associer texte masqué et plusieurs lignes : la
      // garde doit tenir même si l'appelant demande le contraire.
      final champ = await _champ(
        tester,
        const Input(type: InputType.password, maxLines: 5),
      );

      expect(champ.maxLines, 1);
      expect(champ.minLines, isNull);
      expect(champ.keyboardType, TextInputType.text);
    });

    testWidgets('une action imposée par l\'appelant est respectée',
        (tester) async {
      final champ = await _champ(
        tester,
        const Input(maxLines: 3, textInputAction: TextInputAction.done),
      );

      expect(champ.textInputAction, TextInputAction.done);
    });

    testWidgets('on peut vraiment saisir plusieurs lignes', (tester) async {
      final controleur = TextEditingController();
      await _champ(tester, Input(controller: controleur, maxLines: 5));

      await tester.enterText(find.byType(TextField), 'ligne 1\nligne 2');
      await tester.pump();

      expect(controleur.text, 'ligne 1\nligne 2');
      expect(controleur.text.split('\n').length, 2);
    });
  });
}
