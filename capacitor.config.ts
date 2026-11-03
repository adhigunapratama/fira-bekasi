import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'id.co.thco.frida',
  appName: 'FRIDA',
  webDir: 'www',
  android: {
    allowMixedContent: false
  }
};

export default config;
