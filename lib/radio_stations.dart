class RadioStation {
  const RadioStation(this.name, this.country, this.streamUrl);
  final String name;
  final String country;
  final String streamUrl;
}

// Public audio sources observed on Balkan Radio Stanice, 22 October 2026.
const radioStations = <RadioStation>[
  RadioStation(
    "Radio Dženarika",
    "Srbija",
    "https://stream.iradio.pro/proxy/radiodzenarika1?mp=/stream",
  ),
  RadioStation(
    "Plus Forte Bekrija",
    "Македонија",
    "https://radiostream.neotel.mk/plusforteradio",
  ),
  RadioStation("Ok Radio", "Srbija", "https://sslstream.okradio.net/stream"),
  RadioStation("Radio Sehara", "BiH", "https://cast.name.ba:8000/stream"),
  RadioStation("Cool Radio", "Srbija", "https://live.coolradio.rs/cool128"),
  RadioStation(
    "Radio Extra Fm",
    "Hrvatska",
    "https://relay2.social3.hr/radio/8190/radio.mp3",
  ),
  RadioStation(
    "Radio S3 Južni",
    "Srbija",
    "https://stream.radios.rs:9038/stream",
  ),
  RadioStation(
    "Radio Ritam Srca",
    "Srbija",
    "https://s4.radio.co/s0f65dad2d/listen",
  ),
  RadioStation("Radio Big 2", "BiH", "https://big2.bigportal.ba:8080/big2"),
  RadioStation(
    "Naxi Radio Ex Yu",
    "Srbija",
    "https://naxidigital-exyu128ssl.streaming.rs:8242/;",
  ),
  RadioStation(
    "Radio Tim Bitola",
    "Македонија",
    "https://radiotim.radioca.st/stream",
  ),
  RadioStation(
    "Ok Boem",
    "Srbija",
    "https://stream.okplus.rs/listen/boem/radio.mp3",
  ),
  RadioStation(
    "Radio Kavadarci",
    "Македонија",
    "https://stream.zeno.fm/p79t9wf7mg0uv",
  ),
  RadioStation(
    "Radio Extra Fm Throwback",
    "Hrvatska",
    "https://relay2.social3.hr/radio/8170/radio.mp3",
  ),
  RadioStation(
    "Radio SG Juzni Vetar",
    "Srbija",
    "https://radio.dukahosting.com/8445/stream",
  ),
  RadioStation(
    "Radio Lola",
    "Srbija",
    "https://streaming.tdiradio.com/radiolola.mp3",
  ),
  RadioStation("Radio Bn", "BiH", "https://stream.radiobn.net/stream"),
  RadioStation(
    "Radio Nele",
    "Dijaspora",
    "https://radionele.rs/listen/radio_nele/radio.mp3",
  ),
  RadioStation(
    "Radio Mix",
    "BiH",
    "https://stream.rsgmedia.ba/listen/radio_mix/radio.mp3",
  ),
];
