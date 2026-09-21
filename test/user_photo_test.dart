/// Le retrait de la photo de profil.
///
/// `copyWith(photoUrl: null)` ne peut pas vouloir dire « efface » : dans un
/// `copyWith`, une valeur absente signifie « ne change rien ». Sans un drapeau
/// dédié, une photo déposée une fois ne pouvait plus jamais être retirée — ce
/// test existe pour que la distinction ne se reperde pas.
import 'package:flutter_test/flutter_test.dart';

import 'package:ablony/features/auth/domain/entities/auth_provider.dart';
import 'package:ablony/features/auth/domain/entities/country.dart';
import 'package:ablony/features/auth/domain/entities/user.dart';

User _compte({String? photo}) => User(
      uid: 'u1',
      email: 'kodjo@ablony.net',
      username: 'kodjo',
      photoUrl: photo,
      authProvider: AuthProvider.email,
      country: Country.togo,
      acceptedTerms: true,
      acceptedTermsDate: DateTime(2026, 1, 1),
      marketingEmailsEnabled: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      isVerified: true,
      isActive: true,
    );

void main() {
  group('Photo de profil', () {
    test('sans rien préciser, la photo est conservée', () {
      final avant = _compte(photo: 'https://exemple/photo.jpg');
      final apres = avant.copyWith(displayName: 'Kodjo');

      expect(apres.photoUrl, 'https://exemple/photo.jpg');
    });

    test('photoUrl: null ne l\'efface pas — c\'est « ne change rien »', () {
      final avant = _compte(photo: 'https://exemple/photo.jpg');
      final apres = avant.copyWith(photoUrl: null);

      expect(apres.photoUrl, 'https://exemple/photo.jpg');
    });

    test('effacerPhoto la retire vraiment', () {
      final avant = _compte(photo: 'https://exemple/photo.jpg');
      final apres = avant.copyWith(effacerPhoto: true);

      expect(apres.photoUrl, isNull);
    });

    test('effacerPhoto l\'emporte sur une nouvelle adresse', () {
      // Cas de garde : si les deux sont fournis, l'intention d'effacer prime.
      final avant = _compte(photo: 'https://exemple/ancienne.jpg');
      final apres = avant.copyWith(
        photoUrl: 'https://exemple/nouvelle.jpg',
        effacerPhoto: true,
      );

      expect(apres.photoUrl, isNull);
    });

    test('remplacer la photo reste possible', () {
      final avant = _compte(photo: 'https://exemple/ancienne.jpg');
      final apres = avant.copyWith(photoUrl: 'https://exemple/nouvelle.jpg');

      expect(apres.photoUrl, 'https://exemple/nouvelle.jpg');
    });

    test('effacer un compte qui n\'avait pas de photo ne casse rien', () {
      final apres = _compte().copyWith(effacerPhoto: true);

      expect(apres.photoUrl, isNull);
    });

    test('le reste du compte est intact après un effacement', () {
      final avant = _compte(photo: 'https://exemple/photo.jpg');
      final apres = avant.copyWith(effacerPhoto: true);

      expect(apres.uid, avant.uid);
      expect(apres.username, avant.username);
      expect(apres.email, avant.email);
    });
  });
}
