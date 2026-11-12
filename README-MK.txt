Balkan Connect — Neon Design v1

1. Napravi backup od C:\balkan_connect\lib.
2. Raspakuvaj ZIP vo C:\balkan_connect (Merge/Replace samo 3 dart datoteki).
3. cd C:\balkan_connect
4. flutter analyze lib\main.dart lib\marketplace_home.dart lib\balkan_splash.dart
5. Ako nema errors: flutter run -d R58N750QS2E

Vazno: Ova e prv dizajn-prototip so postojeckite assets, ne 1:1 finalniot mockup. Ne e kompajlirano vo ovoj Linux kontejner, zatoa proveri analyze pred build.
