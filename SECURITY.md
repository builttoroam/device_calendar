# 🔐 Security Configuration Guide

## Development Team Setup

1. Her geliştirici kendi `DevelopmentTeam.xcconfig` dosyasını oluşturmalı:
   ```
   DEVELOPMENT_TEAM=YOUR_TEAM_ID
   ```

2. Bu dosya `.gitignore`'da olmalı ve asla commit edilmemeli

3. Xcode'da team seçimi için environment variable kullanın:
   ```
   DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"
   ```

## CI/CD Setup

GitHub Actions için encrypted secrets kullanın:
- `IOS_DEVELOPMENT_TEAM`
- `IOS_SIGNING_IDENTITY` 
- `IOS_PROVISIONING_PROFILE`

## Güvenlik Kontrol Listesi

- [ ] Team ID'ler temizlendi
- [ ] Provisioning profile'lar kaldırıldı  
- [ ] Private key'ler (.p12) kontrol edildi
- [ ] API key'ler kontrol edildi
- [ ] Database connection string'leri kontrol edildi
- [ ] Third-party service token'ları kontrol edildi

## Acil Durum

Eğer hassas bilgi public repo'ya gittiyse:
1. Derhal Apple Developer hesabını kontrol edin
2. Team ID'yi değiştirin (mümkünse)
3. Sertifikaları revoke edin ve yenilerini oluşturun
4. Repository'yi private yapın (geçici)
5. History'yi temizleyin (git filter-repo)