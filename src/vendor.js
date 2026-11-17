import * as Supabase from '@supabase/supabase-js';
import * as LeafletModule from 'leaflet';
import * as Turf from '@turf/turf';

const Leaflet = LeafletModule.default || LeafletModule;
window.supabase = Supabase;
window.L = Leaflet;
window.turf = Turf;

// MarkerCluster extends the global Leaflet instance.
require('leaflet.markercluster');
