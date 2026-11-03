import { Geolocation } from '@capacitor/geolocation';

window.FRIDA_GPS = {
  async getCurrentPosition() {
    try {
      let permission = await Geolocation.checkPermissions();

      if (
        permission.location !== 'granted' &&
        permission.coarseLocation !== 'granted'
      ) {
        permission = await Geolocation.requestPermissions();
      }

      if (
        permission.location !== 'granted' &&
        permission.coarseLocation !== 'granted'
      ) {
        throw new Error('Izin lokasi belum diberikan. Aktifkan izin lokasi FRIDA di pengaturan HP.');
      }

      const position = await Geolocation.getCurrentPosition({
        enableHighAccuracy: true,
        timeout: 20000,
        maximumAge: 0
      });

      return position;
    } catch (error) {
      throw new Error(error.message || 'Gagal mendapatkan lokasi GPS.');
    }
  }
};
