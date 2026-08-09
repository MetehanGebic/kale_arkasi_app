# Kulüp Logoları

Bu klasöre kulüp logolarını PNG olarak ekle. Dosya adı, veritabanındaki
kulübün `slug` alanıyla BİREBİR aynı olmalı (küçük harf, tire ile) —
uygulama dosyayı `assets/images/clubs/<slug>.png` yolundan okuyor.

Beklenen 18 dosya adı (seed.js'teki kulüp listesiyle birebir eşleşiyor):

- amed-sportif-faaliyetler.png
- besiktas.png
- corendon-alanyaspor.png
- caykur-rizespor.png
- corum-fk.png
- erzurumspor-fk.png
- eyupspor.png
- fenerbahce.png
- galatasaray.png
- gaziantep-fk.png
- genclerbirligi.png
- goztepe.png
- istanbul-basaksehir.png
- kasimpasa.png
- kocaelispor.png
- konyaspor.png
- samsunspor.png
- trabzonspor.png

Öneriler:
- Şeffaf arka planlı (transparent) PNG kullan — kartların gradyan
  arka planında en iyi öyle durur.
- Kare veya kareye yakın oranlı görseller kullan; uygulama içinde
  36x36 dairesel bir alana sığdırılıyor (`CircleAvatar` + `ClipOval`).
- Bir kulübün dosyası eksikse ya da bozuksa uygulama çökmez — otomatik
  olarak kulüp adının baş harfini gösteren nötr bir rozete düşer.

Yeni bir kulüp eklersen (seed.js + veritabanı), aynı `slug` ile buraya
bir PNG eklemen yeterli, başka hiçbir kod değişikliği gerekmiyor.
