package vn.hunghd.flutter.plugins.imagecropper;

import android.app.AlertDialog;
import android.os.Bundle;

import androidx.activity.OnBackPressedCallback;

import com.yalantis.ucrop.UCropActivity;

public class ConfirmCropActivity extends UCropActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        android.util.Log.d(
                "FALPETA_CROP",
                "ConfirmCropActivity STARTED"
        );

        getOnBackPressedDispatcher().addCallback(
                this,
                new OnBackPressedCallback(true) {
                    @Override
                    public void handleOnBackPressed() {

                        android.util.Log.d(
                                "FALPETA_CROP",
                                "BACK CALLBACK CALLED"
                        );

                        new AlertDialog.Builder(ConfirmCropActivity.this)
                                .setTitle("トリミングを終了しますか？")
                                .setMessage("トリミング中の変更は破棄されます。")
                                .setNegativeButton("いいえ", null)
                                .setPositiveButton("はい", (dialog, which) -> {
                                    setResult(RESULT_CANCELED);
                                    finish();
                                })
                                .show();
                    }
                }
        );
    }
}