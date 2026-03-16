# Déploiement iOS sur App Store Connect

Ce guide explique comment configurer et déployer l'application MBAHE Europe sur l'App Store via GitHub Actions.

## 📋 Prérequis

### 1. Compte Apple Developer
- Compte Apple Developer actif
- Accès à App Store Connect
- Team ID de votre organisation

### 2. Certificats et Profils de Provisioning

#### a) Certificat de Distribution
1. Aller sur [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Créer un certificat "Apple Distribution"
3. Télécharger le certificat (.cer)
4. L'importer dans Keychain Access
5. Exporter en .p12 (avec mot de passe)
6. Convertir en base64 :
   ```bash
   base64 -i distribution.p12 -o distribution.p12.base64
   ```

#### b) Profil de Provisioning
1. Aller sur [Provisioning Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Créer un profil "App Store" pour votre Bundle ID (`com.mbahe.europe`)
3. Télécharger le profil (.mobileprovision)
4. Convertir en base64 :
   ```bash
   base64 -i mbahe_europe.mobileprovision -o profile.base64
   ```

### 3. App Store Connect API Key

1. Aller sur [App Store Connect API Keys](https://appstoreconnect.apple.com/access/api)
2. Créer une nouvelle clé avec le rôle "Developer" ou "App Manager"
3. Télécharger la clé (.p8) - **ATTENTION : une seule fois !**
4. Noter :
   - **Key ID** (ex: S4DMCPPBB4)
   - **Issuer ID** (UUID dans l'interface)
5. Convertir la clé en base64 :
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 -o api_key.base64
   ```

## 🔐 Configuration des Secrets GitHub

Aller dans **Settings > Secrets and variables > Actions** de votre repository GitHub et ajouter :

| Secret Name | Description | Exemple |
|------------|-------------|---------|
| `P12_BASE64` | Certificat de distribution en base64 | Contenu du fichier .p12.base64 |
| `P12_PASSWORD` | Mot de passe du certificat .p12 | `votre_mot_de_passe` |
| `PROVISION_PROFILE_BASE64` | Profil de provisioning en base64 | Contenu du fichier .mobileprovision.base64 |
| `KEYCHAIN_PASSWORD` | Mot de passe temporaire pour le keychain | `temp_password_123` |
| `DEVELOPMENT_TEAM` | Team ID Apple Developer | `94VW99RYDQ` |
| `APP_STORE_CONNECT_API_KEY_ID` | ID de la clé API App Store Connect | `S4DMCPPBB4` |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID de l'API | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Clé API en base64 | Contenu du fichier .p8.base64 |

## ⚙️ Configuration du Projet iOS

### 1. Mettre à jour ExportOptions.plist

Éditer `ios/ExportOptions.plist` et remplacer :
- `YOUR_TEAM_ID` par votre Team ID
- `YOUR_PROVISIONING_PROFILE_NAME` par le nom exact de votre profil de provisioning

```xml
<key>teamID</key>
<string>94VW99RYDQ</string>
<key>provisioningProfiles</key>
<dict>
    <key>com.mbahe.europe</key>
    <string>MBAHE Europe App Store Profile</string>
</dict>
```

### 2. Vérifier le Bundle ID

Dans `ios/Runner.xcodeproj/project.pbxproj`, vérifier que le Bundle ID est bien `com.mbahe.europe`

### 3. Configurer la version

Dans `pubspec.yaml`, mettre à jour la version :
```yaml
version: 1.0.0+1
```

## 🚀 Déploiement

### Méthode 1 : Déclenchement Manuel
1. Aller dans **Actions** sur GitHub
2. Sélectionner "iOS Build & Deploy to App Store"
3. Cliquer sur "Run workflow"
4. Sélectionner la branche `main`
5. Cliquer sur "Run workflow"

### Méthode 2 : Via Tag Git
```bash
git tag v1.0.0
git push origin v1.0.0
```

## 📱 Après le Déploiement

1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. Sélectionner votre application
3. Aller dans **TestFlight**
4. La build devrait apparaître après traitement (10-30 min)
5. Ajouter des testeurs internes/externes
6. Distribuer la build pour les tests

## 🔍 Dépannage

### Erreur : "No matching provisioning profiles found"
- Vérifier que le Bundle ID correspond exactement
- Vérifier que le profil de provisioning est bien pour "App Store"
- Vérifier que le certificat est valide

### Erreur : "Code signing failed"
- Vérifier le mot de passe du .p12
- Vérifier que le certificat n'est pas expiré
- Vérifier le Team ID

### Erreur : "Upload failed"
- Vérifier les permissions de la clé API
- Vérifier que l'Issuer ID et Key ID sont corrects
- Vérifier que la clé .p8 n'est pas expirée

## 📝 Notes Importantes

- **Certificats** : Valables 1 an, à renouveler annuellement
- **Profils de provisioning** : Valables 1 an, à renouveler annuellement
- **Clés API** : Pas d'expiration, mais peuvent être révoquées
- **Builds** : Conservées 90 jours dans TestFlight
- **Version** : Incrémenter le build number (+1) pour chaque upload

## 🔗 Liens Utiles

- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)
- [TestFlight](https://appstoreconnect.apple.com/apps)
- [Documentation Flutter iOS](https://docs.flutter.dev/deployment/ios)
