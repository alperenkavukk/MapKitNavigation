//
//  ViewController.swift
//  mapKitApp
//
//  Created by Alperen Kavuk on 5.10.2022.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var btnGit: UIButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var oncekikonum : CLLocation?
    var rotalar : [MKDirections] = []
    
     
    let bolgeBuyukluk : Double = 12000
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        konumServisKontrol()
        btnGit.layer.cornerRadius = 30
    }

    func konumServisKontrol(){
        if CLLocationManager.locationServicesEnabled(){
            //konum servşs açılmıştır
            ayarlaLocationManager()
            izinkontrol()
        }
        else{
            
        }
}
    
    func ayarlaLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    
    func konumOdaklan(){
        if let konum = locationManager.location?.coordinate {
            let bolge = MKCoordinateRegion.init(center: konum, latitudinalMeters: bolgeBuyukluk , longitudinalMeters: bolgeBuyukluk)
            mapView.setRegion(bolge, animated: true)
        }
    }
    
    func izinkontrol(){
        switch CLLocationManager.authorizationStatus(){
            
        case .authorizedAlways:
            //kullanıcı daima kullanmak için izin vermiştir
            break
        case .authorizedWhenInUse:
            //sadece uygulama açıkkken kullanıma izin verildi
           kullanicitakip()
            break
        case .denied:
            //kullanıcı izin vermedi
            break
        case .notDetermined:
            //kullanıcı herhangi bir karar vermedi
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //uygulamnın durumu kısıtlandı
            break
        
        
        }
    }
    
    func kullanicitakip(){
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        konumOdaklan()
        oncekikonum = merkezKordinatlarıGetir(mapVİew: mapView)
    }
    
    func merkezKordinatlarıGetir(mapVİew : MKMapView) -> CLLocation{
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapVİew.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    @IBAction func btngitTikla(_ sender: Any) {
        rotaBelirle()
    }
    
    
    func rotaBelirle(){
        
        guard let baslangicKoordinat = locationManager.location?.coordinate else { return}
        let istek = istekOlustur(baslangicKoordinati:   baslangicKoordinat)
        let rotalar = MKDirections(request: istek)
        mapViewTemizle(yeniRota: rotalar)
        rotalar.calculate { ( cevap , hata) in
            guard let cevap = cevap else { return}
            
            for rota in cevap.routes {
                self.mapView.addOverlay(rota.polyline)
                self.mapView.setVisibleMapRect(rota.polyline.boundingMapRect,animated: true)
            }
            
        }
        
    }
    func istekOlustur (baslangicKoordinati : CLLocationCoordinate2D) -> MKDirections.Request {
        let hedefKoordinat =  merkezKordinatlarıGetir(mapVİew: mapView).coordinate
        let baslangicNoktasi = MKPlacemark(coordinate: baslangicKoordinati)
        let hedefNoktasi = MKPlacemark(coordinate: hedefKoordinat)
        
        let istek = MKDirections.Request()
        istek.source = MKMapItem(placemark: baslangicNoktasi)
        istek.destination = MKMapItem(placemark: hedefNoktasi)
        istek.transportType = .automobile
        istek.requestsAlternateRoutes = true
        
        return istek
        
    }
    
}
extension ViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //konum güncellenirse tetiklenir
        guard let konum = locations.last else {return}
        let merkez = CLLocationCoordinate2D(latitude: konum.coordinate.latitude, longitude: konum.coordinate.longitude)
        let bolge = MKCoordinateRegion.init(center: merkez, latitudinalMeters: bolgeBuyukluk, longitudinalMeters: bolgeBuyukluk)
        mapView.setRegion(bolge, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //konuma verilen izin değiştirilirse
        izinkontrol()
    }
    func mapViewTemizle(yeniRota : MKDirections){
        mapView.removeOverlays(mapView.overlays)
        rotalar.append(yeniRota)
        
        let _ = rotalar.map {$0.cancel()}
    }
    
}

extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let merkez = merkezKordinatlarıGetir(mapVİew: mapView)
        
        guard let oncekikonum = self.oncekikonum else    {
            return
        }
        if merkez.distance(from: oncekikonum) < 50 {return}
        self.oncekikonum = merkez
        
        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(merkez){ ( yerisaretleri , hata) in
            if let _ = hata {
                print("hata meydana geldi")
                return
            }
            guard let isaret = yerisaretleri?.first else {
                 return
                
            }
        /*    let sokokNumarasi = isaret.subThoroughfare ?? "yok"
            let sokokAdi =  isaret.thoroughfare ?? "yok"
           */ let ulkeAdi = isaret.country ?? "yok"
            let ilAdı = isaret.administrativeArea ?? "yok"
            let ilceAdi = isaret.locality ?? "yok"
            
            
            DispatchQueue.main.async {
                self.label.text = "\(ilceAdi) /\(ilAdı) /\(ulkeAdi)"
            }
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor =  .red
        renderer.lineWidth = 9
        renderer.lineCap = .square
        return renderer
    }
}
