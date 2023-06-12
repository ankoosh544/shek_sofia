  

using Mcallin.Xamarin.Enums;
using Mcallin.Xamarin.Interfaces;
using Mcallin.Xamarin.Models;
using Mcallin.Xamarin.Views;
using Plugin.BLE;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Essentials;
using Xamarin.Forms;
using static Mcallin.Xamarin.Interfaces.ICoreController;


namespace Mcallin.Xamarin
{
  
    public class CoreController : ICoreController
    {

        #region Constants

        private const int SCAN_TIMEOUT = -1;                // infinito

        private const int REFRESH_TIMEOUT = 500;            // 500 ms
        private const double MIN_CAR_RX_POWER = -700;

        private const string FLOOR_REQUEST_CHARACTERISTIC_GUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; //usato per inviare nuove piano di destinazione e priorità

        private const string FLOOR_CHANGE_CHARACTERISTIC_GUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9"; // invia al telefono dove si trova la cabina
        private const string MISSION_STATUS_CHARACTERISTIC_GUID = "beb5483e-36e1-4688-b7f5-ea07361b26aa"; // cabina la piano di destinazione

        private const string OUT_OF_SERVICE_CHARACTERISTIC_GUID = "beb5483e-36e1-4688-b7f5-ea07361b26ab"; // out of service lift default 0

        private const string MOVEMENT_DIRECTION_CAR = "beb5483e-36e1-4688-b7f5-ea07361b26ac"; // movimento e direzione della cabina
                                                                                              // byte 0 = 1 cabina in movimento
                                                                                              // byte 1 = 0 Cabina su
                                                                                              // byte 1 = 1 Cabina giù
        List<String> Characteristics = new List<String>();

        int IntervalloAvvisoVicinoAscensore = 60; // in secondi
        long tickAttuali = 0;// memorizza il valore di tick corrente
        long SecondiPassati = 0;
        Boolean PrimaConnessioneDevice = true;

        Boolean ConnessioneInCorso = false;

        

        #endregion

        #region Fields

        private IAuthService authService;
        private IBLEService bleService;
        private INearestDeviceResolver resolver;
        private INotificationManager notificationManager;
        private IAudioService audioService;
        private IDataLoggerService dataloggerService;

        private bool isStarted = false;

        #endregion

        #region Properties


        public bool IsInForeground { get; set; }

      
        public List<BLEDevice> Devices => this.resolver.Devices;

        public BLEDevice NearestDevice => this.resolver.NearestDevice;

  
        public BLEDevice Car => this.FindCar(this.Devices);

      
        public User LoggerUser { get; set; }

       
        public IDataLoggerService DataLogger => this.dataloggerService;

     
        public OperationMode OperationMode { private set; get; }

        //Mario - Proprietà per OutOfService e AssenzaLuce
        public Boolean OutOfService { get; set; } = false; // MARIO SIMULAZIONE OUTOFORDER false;

        public Boolean PresenceOfLight { get; set; } = true;

        //Mario - Posizione della cabina
        public string CarFloor { get; set; } = "--";



        public Direction CarDirection { get; set; } = Direction.Stopped; // 0=su, 1 = giu


        public byte MissionStatus { get; set; } = (int)TypeMissionStatus.MISSION_NO_INIT;

        public int Eta { get; set; } = -1;



        #endregion

        #region Events

        public event EventHandler<BLEDevice> OnNearestDeviceChanged;

        public event EventHandler<string> OnFloorChanged;

        public event EventHandler OnMissionStatusChanged;

        public event EventHandler OnCharacteristicUpdated;


        public event EventHandler OnDeviceDisconnected;

        #endregion

        #region Constructor

        public CoreController()
        {
            this.authService = DependencyService.Get<IAuthService>();
            this.bleService = DependencyService.Get<IBLEService>();
            this.notificationManager = DependencyService.Get<INotificationManager>();
            this.resolver = DependencyService.Get<INearestDeviceResolver>();
            this.audioService = DependencyService.Get<IAudioService>();
            this.dataloggerService = DependencyService.Get<IDataLoggerService>();

            this.notificationManager.NotificationReceived += NotificationManager_NotificationReceived;
            this.bleService.OnSampleReceived += BleService_OnSampleReceived;
            this.bleService.OnDeviceDisconnected += BleService_OnDeviceDisconnected;
            this.resolver.OnNearestDeviceChanged += Resolver_NearestDeviceChanged;

            this.bleService.Timer1msTickk();
            Characteristics.Add(FLOOR_CHANGE_CHARACTERISTIC_GUID);
            Characteristics.Add(MISSION_STATUS_CHARACTERISTIC_GUID);
            Characteristics.Add(OUT_OF_SERVICE_CHARACTERISTIC_GUID);
            //Characteristics.Add(MOVEMENT_DIRECTION_CAR);
        }

        private void BleService_OnDeviceDisconnected(object sender, EventArgs e)
        {
            try
            {
                if (this.OnDeviceDisconnected != null)
                {
                    this.OnDeviceDisconnected(this, null);
                }
            }
            catch (Exception ex)
            {

                if(Preferences.Get("DevOptions", false) == true)
                {
                    App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                }
                else
                {
                    Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);
                }
                


                
                


            }
        }

#endregion

#region Methods


        public async Task StartScanningAsync()
        {
            this.isStarted = true;
            this.notificationManager.Initialize();
            this.OperationMode = OperationMode.DeviceScanning;

            Device.StartTimer(TimeSpan.FromMilliseconds(REFRESH_TIMEOUT), () =>
            {
                // il refresh in polling viene fatto solo se non ricevo più campioni dal nearest device
                if (this.NearestDevice != null && !this.NearestDevice.IsAlive)
                    this.resolver.RefreshNearestDevice(DateTime.Now);

                return this.isStarted;
            });

            await this.bleService.StartScanningAsync(SCAN_TIMEOUT);
        }


        public async Task StopScanningAsync()
        {
            this.isStarted = false;
            this.OperationMode = OperationMode.Idle;
            await this.bleService.StopScanningAsync();
        }

    
        public async Task ChangeFloorAsync(byte[] destinationFloor)
        {
            try
            {
                // cambio modalità operativa
                this.OperationMode = OperationMode.ChangeFloorMission;

                // connessione dispositivo più vicino
                await this.bleService.ConnectToDeviceAsync(this.NearestDevice.Id);

                // invio comando BLE


                await this.bleService.SendCommandAsync(IBLEService.FLOOR_SERVICE_GUID, FLOOR_REQUEST_CHARACTERISTIC_GUID, destinationFloor);

                // avvio monitoraggio "Cambio piano" e "Fine monitoraggio"
                //  await StartCharacteristicWatchAsync();
            }
            catch (Exception)
            {
if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", "Errore invio chiamata", "Ok");
else
                Debug.Print("Errore invio chiamata");

            }


        }

        private void BleService_OnSampleReceived(object sender, BLESample sample)
        {

            this.dataloggerService.AddSample(sample);
            this.resolver.AddSample(sample);
        }

        public async Task ConnectDevice(BLEDevice device)
        {
            try
            {
                Debug.Print("Alias device: ");
                Debug.Print(device.Alias);
                if (this.bleService.ConnectedDeviceId != null)
                {
                    if (device == null) { return; }
                    if (String.IsNullOrEmpty(this.bleService.ConnectedDeviceId))
                    {
                        await ConnectDeviceAndRead(device);
                    }

                }
            }
            catch (Exception ex)
            {
if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
else
                Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);

            }

        }



     

        private async Task ConnectDeviceAndRead(BLEDevice device)
        {
            try
            {
                

                if (this.bleService.ConnectedDeviceId.ToString() == "")
                {
                    if (device != null)
                    {
                       
                        
                        await this.bleService.ConnectToDeviceAsync(device.Id);

                        await Get_Piano_Cabina();
                        await StartCharacteristicReadWatchAsync();
                    }
                    return;
                }
            }
            catch (Exception ex)
            {
                if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                else
                Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);

            }

            try
            {


                if (this.bleService.ConnectedDeviceId.ToString() != device.Id.ToString())
                {
                    await StopCharacteristicWatchAsync();
                    await this.bleService.DisconnectToDeviceAsync();

                    await this.bleService.ConnectToDeviceAsync(device.Id);
                    //await Get_Piano_Cabina();
                    await StartCharacteristicReadWatchAsync();
                    return;
                }
            }
            catch (Exception ex)
            {
if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
else
                Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);

            }
        }


   
        private async void Resolver_NearestDeviceChanged(object sender, BLEDevice device)
        {
            
            if (device == null)
            {
                return;
            }

           


            if (ConnessioneInCorso == true) { return; }
            ConnessioneInCorso = true;
            await ConnectDeviceAndRead(device);

            // invio segnalazioni (vibrazione + audio) e notifica
            if (device != null)
                EmitNotifications(device);

            // invio evento
            if (this.OnNearestDeviceChanged != null)
                this.OnNearestDeviceChanged(this, device);

            // se "ChangeFloor" => connessione automatica per ricevere le notifiche di cambio piano e fine missione
            if (this.OperationMode == OperationMode.ChangeFloorMission)
            {
                // disconnessione precedente device connesso
                if (!String.IsNullOrEmpty(this.bleService.ConnectedDeviceId))
                {
                    await this.bleService.DisconnectToDeviceAsync();
                    await StopCharacteristicWatchAsync();


                    // connessione dispositivo più vicino
                    await this.bleService.ConnectToDeviceAsync(device.Id);
                    await StartCharacteristicReadWatchAsync();
                    //MARIO    await ConnectDeviceAndRead(device);
                }
            }

            ConnessioneInCorso = false;
            //await StartCharacteristicWatchAsync();
        }

    
        private async Task StartCharacteristicReadWatchAsync()
        {
            byte Value;
            //lettura valori delle caratteristiche

            try
            {


                foreach (string Characteristic in Characteristics)
                {
                    Value = 0;
                    //try
                    //{
                    if(NearestDevice != null)
                    {
                        if (this.NearestDevice.IsAlive == true )
                        {
                            await this.bleService.GetValueFromCharacteristicGuid(IBLEService.FLOOR_SERVICE_GUID, Characteristic);
                        }
                    }
                    
                  

                    BLECharacteristicEventArgs bl = new BLECharacteristicEventArgs
                    {
                        Value = this.bleService.ValueFromCharacteristic,
                        CharacteristicGuid = Characteristic
                    };
                    Debug.Print("La caratteristica {0} ha il valore {1}", Characteristic, Value);
                    if (bl.Value != null)
                    {
                        BleService_OnCharacteristicUpdated(this, bl);
                    }


                }

                // sottoscrizione eventi cambio valore caratteristica


                this.bleService.OnCharacteristicUpdated += BleService_OnCharacteristicUpdated;
                //Debug.Print("*************** Start watch caratteristics ***************");
                foreach (string Characteristic in Characteristics)
                {
                    await this.bleService.StartCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, Characteristic);
                    //Debug.Print("Wach della caratteristica " + Characteristic.ToString());
                }
               
            }
            catch (Exception ex)
            {
                if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                else
                Debug.Print( ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);

            }





        }


        private async Task StopCharacteristicWatchAsync()
        {
            try
            {


                // sottoscrizione eventi cambio valore caratteristica
                this.bleService.OnCharacteristicUpdated -= BleService_OnCharacteristicUpdated;



                await this.bleService.StopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, FLOOR_CHANGE_CHARACTERISTIC_GUID);
                await this.bleService.StopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, MISSION_STATUS_CHARACTERISTIC_GUID);

                //Mario - Stop Monitoraggio di out of service e assenza di luce letto dal piano
                await this.bleService.StopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, OUT_OF_SERVICE_CHARACTERISTIC_GUID);

                //Mario aggiunto movimento della cabina
                await this.bleService.StopCharacteristicWatchAsync(IBLEService.FLOOR_SERVICE_GUID, MOVEMENT_DIRECTION_CAR);

                Debug.Print("*************** Stop watch caratteristics ***************");
            }
            catch (Exception)
            {
               

            }
        }


      

        public async Task Get_Piano_Cabina()
        {
            try
            {
                CarFloor = "999";
                if (this.bleService.ConnectedDeviceId.ToString() != "")
                {
                    try
                    {
                        await this.bleService.GetValueFromCharacteristicGuid(IBLEService.FLOOR_SERVICE_GUID, FLOOR_CHANGE_CHARACTERISTIC_GUID);
                    }
                    catch (Exception )
                    {
                        return;
                        //await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                    }
                    if (bleService.ValueFromCharacteristic != null)
                    {
                        try
                        {
                            CarFloor = ((byte)bleService.ValueFromCharacteristic[0] & 0x3F).ToString();
                        }
                        catch (Exception)
                        {
                            if (Preferences.Get("DevOptions", false) == true)
                            {
                                CarFloor = "*****";
                                //Debug.Print("***** Caratteristica non trovata ******");
                            }

                        }

                    }
                    else
                    {
                        CarFloor = "999";
                    }
                }
            }

            catch (Exception ex)
            {
                if(Preferences.Get("DevOptions", false) == true)
                await App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                else
                Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);

            }


        }

     
        private void BleService_OnCharacteristicUpdated(object sender, BLECharacteristicEventArgs e)
        {
            try
            {


                switch (e.CharacteristicGuid)
                {

                    case FLOOR_CHANGE_CHARACTERISTIC_GUID:
                        try
                        {
                            //if (e.Value[0] != 0)
                            //{
                                CarFloor = ((byte)e.Value[0] & 0x3F).ToString();
                            // Debug.Print(CarFloor);
                            //if (this.OnFloorChanged != null)
                            //{
                            //    this.OnFloorChanged(this, CarFloor.ToString());
                            //}

                            if (((byte)e.Value[0] & 0x40) == (0x40))
                                this.PresenceOfLight = true;
                            else
                            {
                                this.PresenceOfLight = false;
                            }

                            if (((byte)e.Value[1] & 0x1) == (0x1))
                            {

                                if (((byte)e.Value[1] & 0x02) == (0x02))
                                {
                                    CarDirection = Direction.Up;
                                    //Debug.Print("CarDirection: " + CarDirection + "\r\n");

                                }
                                else
                                {
                                    CarDirection = Direction.Down;
                                    //Debug.Print("CarDirection: " + CarDirection + "\r\n");
                                }
                            }
                            else
                            {
                                CarDirection = Direction.Stopped;
                                //Debug.Print("CarDirection: " + CarDirection + "\r\n");
                            }

                            //}
                        }
                        catch (Exception ex)
                        {
                            if(Preferences.Get("DevOptions", false) == true)
                            App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                            else
                            Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);


                        }
                        break;

                    case MISSION_STATUS_CHARACTERISTIC_GUID:
                       
                        try
                        {
                            if (e.Value.Count() > 2)
                            {
                                MissionStatus = e.Value[0];
                                Eta = e.Value[1] * 256 + e.Value[2];
                            }
                            if (this.OnMissionStatusChanged != null)
                                this.OnMissionStatusChanged(this, null);
                        }
                        catch (Exception ex)
                        {
                            if(Preferences.Get("DevOptions", false) == true)
                            App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
                            else
                            Debug.Print(ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source);


                        }

                        break;
                    case OUT_OF_SERVICE_CHARACTERISTIC_GUID:
                        if (e.Value[0] == 0)
                        {
                            this.OutOfService = false;
                        }
                        else
                        {
                            this.OutOfService = true;
                        }
                        break;
                    case MOVEMENT_DIRECTION_CAR:
                        byte Valore = (byte)e.Value[0];
                        if (((byte)e.Value[0] & 0x1) == (0x1))
                        {

                            if (((byte)e.Value[0] & 0x02) == (0x02))
                            {
                                CarDirection = Direction.Up;

                            }
                            else
                            {
                                CarDirection = Direction.Down;
                            }
                        }
                        else
                        {
                            CarDirection = Direction.Stopped;
                        }

                        break;

                }

                // invio evento
                if (this.OnCharacteristicUpdated != null)
                    this.OnCharacteristicUpdated(this, null);


            }
            catch (Exception ex)
            {
                App.Current.MainPage.DisplayAlert("Alert", ex.Message + "\r\n" + ex.StackTrace + "\r\n" + ex.Source, "OK");
               

            }
        }

        private bool IsFloor(BLEDevice device)
        {
            return device != null && device.Type == BLEDeviceType.Floor;
        }

        
        private void EmitNotifications(BLEDevice device)
        {

            if (IsFloor(device))
            {
                if (!this.IsInForeground)
                {
                   
                    SecondiPassati = ((DateTime.Now.Ticks - tickAttuali) / TimeSpan.TicksPerSecond);
                    Debug.Print("secondi:");
                    Debug.Print(SecondiPassati.ToString());
                    if ((SecondiPassati > IntervalloAvvisoVicinoAscensore) || (PrimaConnessioneDevice == true))
                    {
                        PrimaConnessioneDevice = false;
                        Vibration.Vibrate();
                        this.notificationManager.SendNotification("Soffia", Res.AppResources.YouAreNearTheElevator);
                        this.audioService.Beep();
                        tickAttuali = DateTime.Now.Ticks;
                    }
                    
                }

            }




        }

       
        private async void NotificationManager_NotificationReceived(object sender, EventArgs e)
        {
            if (await this.authService.IsLoggedAsync())
            {
                await Shell.Current.GoToAsync("//CommandPage");                               
            }
            else
            {
                await Shell.Current.GoToAsync("//LoginPage");                
            }
        }

        /// <summary>
        /// Ricerca dispositivo cabine
        /// </summary>
        /// <param name="devices"></param>
        /// <returns></returns>
        private BLEDevice FindCar(List<BLEDevice> devices)
        {
            var carDevice = devices.FirstOrDefault(d => d.Type == BLEDeviceType.Car);
            var isNear = carDevice != null && carDevice.AvgRxPower.HasValue && carDevice.AvgRxPower.Value > MIN_CAR_RX_POWER;
            return isNear ? carDevice : null;
        }

#endregion
    }
}
