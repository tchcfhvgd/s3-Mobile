#if !macro
import flixel.FlxG;

//Mobile Controls
import mobile.objects.MobileControls;
import mobile.objects.IMobileControls;
import mobile.objects.Hitbox;
import mobile.objects.TouchPad;
import mobile.objects.TouchButton;
import mobile.input.MobileInputID;
import mobile.backend.MobileData;
import mobile.input.MobileInputManager;
import mobile.backend.TouchUtil;
import mobile.backend.StorageUtil;

// Android
#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
import android.os.BatteryManager as AndroidBatteryManager;
#end

using StringTools;
#end
