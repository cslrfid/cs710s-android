# CS710 QuickStart App - Technical Documentation

**Module**: cs710aquickstart
**Status**: ✅ **Production Ready**
**Last Updated**: January 2025
**Version**: 1.0.0

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Application Architecture](#application-architecture)
3. [Activities](#activities)
4. [ViewModels](#viewmodels)
5. [RecyclerView Adapters](#recyclerview-adapters)
6. [UI Resources](#ui-resources)
7. [Key Features](#key-features)
8. [User Workflows](#user-workflows)
9. [Build and Deployment](#build-and-deployment)
10. [Testing Guide](#testing-guide)

---

## Executive Summary

The **CS710 QuickStart** app is a production-ready Android application demonstrating RFID operations using the `csl-rfid-android-sdk`. It showcases:

- **Complete RFID Workflows**: Scan, connect, inventory, Geiger search
- **MVVM Architecture**: Clean separation with ViewModels and LiveData
- **Material Design**: Modern Android UI with RecyclerViews
- **Automatic Configuration**: Reader settings applied on inventory load
- **Production Features**: RSSI in dBm, CSL branding, error handling

### Module Status

| Component | Status | Details |
|-----------|--------|---------|
| MainActivity | ✅ Complete | Home screen with navigation |
| ScanActivity | ✅ Complete | Reader scanning with loading overlay |
| InventoryActivity | ✅ Complete | Tag inventory with trigger support |
| GeigerSearchActivity | ✅ Complete | Tag locating with trigger support |
| ScanViewModel | ✅ Complete | Scan logic with connection states |
| InventoryViewModel | ✅ Complete | Inventory logic |
| GeigerViewModel | ✅ Complete | Geiger logic |
| UI Layouts | ✅ Complete | 7 XML layouts |
| **Total** | **✅ Production Ready** | **~1,850 lines** |

---

## Application Architecture

### Module Structure

```
cs710aquickstart/
├── src/main/java/com/csl/cs710aquickstart/
│   ├── QuickStartApplication.java      # Application singleton
│   ├── MainActivity.java               # Home screen
│   ├── ScanActivity.java               # Reader scanning
│   ├── InventoryActivity.java          # Tag inventory
│   ├── GeigerSearchActivity.java       # Tag locating
│   │
│   ├── viewmodels/                     # MVVM ViewModels
│   │   ├── ScanViewModel.java          # Scan logic
│   │   ├── InventoryViewModel.java     # Inventory logic
│   │   └── GeigerViewModel.java        # Geiger logic
│   │
│   └── adapters/                       # RecyclerView Adapters
│       ├── ReaderListAdapter.java      # Reader list display
│       └── TagListAdapter.java         # Tag list display
│
├── src/main/res/
│   ├── layout/                         # UI layouts
│   │   ├── activity_main.xml           # Home screen
│   │   ├── activity_scan.xml           # Scan screen
│   │   ├── activity_inventory.xml      # Inventory screen
│   │   ├── activity_geiger_search.xml  # Geiger screen
│   │   ├── loading_overlay.xml         # Connection loading overlay
│   │   ├── item_reader.xml             # Reader list item
│   │   └── item_tag.xml                # Tag list item
│   │
│   ├── mipmap-*/                       # App icons
│   │   └── csl_java_logo_230510.png    # CSL logo (all densities)
│   │
│   └── values/
│       └── strings.xml                 # String resources
│
└── src/main/AndroidManifest.xml        # App manifest
```

### MVVM Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Activities)           │
│  User interaction, view updates         │
└─────────────────────────────────────────┘
                    ↓
              LiveData observe
                    ↓
┌─────────────────────────────────────────┐
│      ViewModel Layer (LiveData)         │
│  Business logic, state management       │
└─────────────────────────────────────────┘
                    ↓
              SDK callbacks
                    ↓
┌─────────────────────────────────────────┐
│   SDK Wrapper (RfidManager)             │
│  RFID operations, configuration         │
└─────────────────────────────────────────┘
```

### Design Principles

1. **MVVM Pattern**: Activities observe ViewModels via LiveData
2. **Lifecycle Aware**: ViewModels survive configuration changes
3. **Single Responsibility**: Each Activity handles one feature
4. **Reactive UI**: LiveData-driven UI updates
5. **Clean Navigation**: Simple Intent-based navigation

---

## Activities

### 1. MainActivity

**File**: `MainActivity.java` (~120 lines)

**Purpose**: Home screen with navigation to features

**Key Features**:
- Navigation buttons to all features
- Connection status display
- Permission request handling
- About information

**Layout**: `activity_main.xml`
- Vertical LinearLayout
- Material buttons for each feature
- TextView for connection status

**Key Methods**:

```java
public class MainActivity extends AppCompatActivity {
    private RfidManager rfidManager;
    private TextView textConnectionStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Get RfidManager singleton
        QuickStartApplication app = (QuickStartApplication) getApplication();
        rfidManager = app.getRfidManager();

        // Setup buttons
        findViewById(R.id.btnScan).setOnClickListener(v -> {
            startActivity(new Intent(this, ScanActivity.class));
        });

        findViewById(R.id.btnInventory).setOnClickListener(v -> {
            startActivity(new Intent(this, InventoryActivity.class));
        });

        findViewById(R.id.btnGeiger).setOnClickListener(v -> {
            startActivity(new Intent(this, GeigerSearchActivity.class));
        });

        // Request permissions
        requestPermissions();
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateConnectionStatus();
    }

    private void updateConnectionStatus() {
        if (rfidManager.isConnected()) {
            RfidReader reader = rfidManager.getConnectedReader();
            textConnectionStatus.setText("Connected: " + reader.getName());
        } else {
            textConnectionStatus.setText("Not connected");
        }
    }
}
```

### 2. ScanActivity

**File**: `ScanActivity.java` (~158 lines)

**Purpose**: Scan for and connect to RFID readers

**Key Features**:
- BLE scanning with live results
- RecyclerView showing discovered readers
- Click reader to connect
- Scan/Stop button
- **Loading overlay during connection/initialization**
- Connection status feedback
- Error handling with Toasts
- Automatic navigation to inventory when reader ready

**Layout**: `activity_scan.xml`
- Button for scan control
- RecyclerView for reader list
- ProgressBar for scanning indicator
- Loading overlay with status messages

**ViewModel**: ScanViewModel

**Key Implementation**:

```java
public class ScanActivity extends AppCompatActivity {
    private ScanViewModel viewModel;
    private ReaderListAdapter adapter;
    private Button btnScan;
    private RecyclerView recyclerViewReaders;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(ScanViewModel.class);

        // Setup RecyclerView
        adapter = new ReaderListAdapter(this::onReaderClick);
        recyclerViewReaders.setAdapter(adapter);

        // Observe readers
        viewModel.getReaders().observe(this, readers -> {
            adapter.submitList(readers);
        });

        // Observe scanning state
        viewModel.isScanning().observe(this, scanning -> {
            if (scanning) {
                btnScan.setText(R.string.btn_stop_scan);
            } else {
                btnScan.setText(R.string.btn_start_scan);
            }
        });

        // Observe errors
        viewModel.getErrors().observe(this, error -> {
            if (error != null) {
                Toast.makeText(this, error.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        // Scan button
        btnScan.setOnClickListener(v -> {
            Boolean scanning = viewModel.isScanning().getValue();
            if (scanning != null && scanning) {
                viewModel.stopScan();
            } else {
                viewModel.startScan();
            }
        });
    }

    private void onReaderClick(RfidReader reader) {
        viewModel.connectToReader(reader);
    }

    @Override
    protected void onDestroy() {
        viewModel.stopScan();
        super.onDestroy();
    }
}
```

### 3. InventoryActivity

**File**: `InventoryActivity.java` (~252 lines)

**Purpose**: Read RFID tags and display statistics

**Key Features**:
- Start/Stop inventory button
- RecyclerView showing tag list (EPC, RSSI, count)
- Real-time statistics display (with visibility management)
- **Battery level monitoring** (displayed in action bar)
- **Trigger key support** (hardware button controls start/stop)
- Clear tags button
- Click tag to navigate to Geiger search
- **Automatic configuration on load**
- Error handling

**Layout**: `activity_inventory.xml`
- Button for inventory control
- Button for clear
- TextView for statistics
- RecyclerView for tag list

**ViewModel**: InventoryViewModel

**Configuration Auto-Application**:

```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_inventory);

    // Setup ViewModel
    viewModel = new ViewModelProvider(this).get(InventoryViewModel.class);

    // Setup views and observers...

    // Apply configuration if connected
    if (viewModel.getRfidManager().isConnected()) {
        applyReaderConfiguration();
    }
}

/**
 * Apply reader configuration when inventory page loads
 * Configuration as specified in rfid-wrapper-proposal.md section 3.4
 */
private void applyReaderConfiguration() {
    viewModel.getRfidManager().configure()
            .powerLevel(300)                          // 30.0 dBm
            .session(1)                               // Session 1
            .target(RfidTarget.A)                     // Target A
            .inventoryMode(RfidInventoryMode.COMPACT) // Compact mode
            .qValue(7)                                // Q = 7
            .enableBeep(true)                         // Enable beep
            .enableVibrate(true)                      // Enable vibrate
            .apply(new RfidConfigurationCallback() {
                @Override
                public void onConfigured() {
                    Toast.makeText(InventoryActivity.this,
                            "Reader configured successfully",
                            Toast.LENGTH_SHORT).show();
                }

                @Override
                public void onConfigurationFailed(RfidError error) {
                    Toast.makeText(InventoryActivity.this,
                            "Configuration failed: " + error.getMessage(),
                            Toast.LENGTH_LONG).show();
                }
            });
}
```

**Observer Setup**:

```java
// Observe tags
viewModel.getTags().observe(this, tags -> {
    adapter.submitList(tags);
    if (tags.isEmpty()) {
        textEmpty.setVisibility(View.VISIBLE);
        recyclerViewTags.setVisibility(View.GONE);
    } else {
        textEmpty.setVisibility(View.GONE);
        recyclerViewTags.setVisibility(View.VISIBLE);
    }
});

// Observe stats
viewModel.getStats().observe(this, stats -> {
    if (stats != null) {
        textStats.setText(String.format(
                getString(R.string.stats_format),
                stats.getUniqueTagCount(),
                stats.getTotalReads(),
                stats.getReadRate()
        ));
    }
});

// Observe inventory state
viewModel.isInventorying().observe(this, inventorying -> {
    if (inventorying) {
        btnInventory.setText(R.string.btn_stop_inventory);
    } else {
        btnInventory.setText(R.string.btn_start_inventory);
    }
});
```

**Tag Click Navigation**:

```java
private void onTagClick(RfidTag tag) {
    // Navigate to Geiger search with this tag
    Intent intent = new Intent(this, GeigerSearchActivity.class);
    intent.putExtra("TARGET_EPC", tag.getEpc());
    startActivity(intent);
}
```

### 4. GeigerSearchActivity

**File**: `GeigerSearchActivity.java` (~235 lines)

**Purpose**: Locate a specific tag using RSSI proximity

**Key Features**:
- Target EPC input (EditText or Intent extra)
- Start/Stop search button
- Real-time RSSI display (current and peak)
- Proximity bar (ProgressBar 0-100%)
- Read count display
- Visual feedback (color-coded proximity)
- **Battery level monitoring** (displayed in action bar)
- **Trigger key support** (hardware button controls start/stop)
- Error handling

**Layout**: `activity_geiger_search.xml`
- EditText for target EPC
- Button for search control
- TextViews for RSSI and stats
- ProgressBar for proximity
- Color-coded feedback

**ViewModel**: GeigerViewModel

**Key Implementation**:

```java
public class GeigerSearchActivity extends AppCompatActivity {
    private GeigerViewModel viewModel;
    private EditText editTargetEpc;
    private Button btnSearch;
    private TextView textCurrentRssi;
    private TextView textPeakRssi;
    private TextView textReadCount;
    private ProgressBar progressProximity;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_geiger_search);

        // Setup ViewModel
        viewModel = new ViewModelProvider(this).get(GeigerViewModel.class);

        // Get target EPC from intent (from InventoryActivity)
        Intent intent = getIntent();
        if (intent.hasExtra("TARGET_EPC")) {
            String targetEpc = intent.getStringExtra("TARGET_EPC");
            editTargetEpc.setText(targetEpc);
        }

        // Observe stats
        viewModel.getStats().observe(this, stats -> {
            if (stats != null) {
                updateProximityDisplay(stats);
            }
        });

        // Observe searching state
        viewModel.isSearching().observe(this, searching -> {
            if (searching) {
                btnSearch.setText(R.string.btn_stop_search);
                editTargetEpc.setEnabled(false);
            } else {
                btnSearch.setText(R.string.btn_start_search);
                editTargetEpc.setEnabled(true);
            }
        });

        // Search button
        btnSearch.setOnClickListener(v -> {
            Boolean searching = viewModel.isSearching().getValue();
            if (searching != null && searching) {
                viewModel.stopSearch();
            } else {
                String targetEpc = editTargetEpc.getText().toString().trim();
                if (!targetEpc.isEmpty()) {
                    viewModel.startSearch(targetEpc);
                } else {
                    Toast.makeText(this, "Enter target EPC", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    private void updateProximityDisplay(RfidGeigerStats stats) {
        // Update RSSI displays
        textCurrentRssi.setText(String.format("%.1f dBm", stats.getCurrentRssi()));
        textPeakRssi.setText(String.format("%.1f dBm", stats.getPeakRssi()));
        textReadCount.setText(String.valueOf(stats.getReadCount()));

        // Update proximity bar
        progressProximity.setProgress(stats.getProximity());

        // Color-coded feedback
        int color;
        if (stats.getProximity() > 75) {
            color = Color.GREEN;  // Very close
        } else if (stats.getProximity() > 50) {
            color = Color.YELLOW; // Close
        } else if (stats.getProximity() > 25) {
            color = Color.ORANGE; // Medium
        } else {
            color = Color.RED;    // Far
        }
        progressProximity.getProgressDrawable().setColorFilter(color, PorterDuff.Mode.SRC_IN);
    }

    @Override
    protected void onDestroy() {
        viewModel.stopSearch();
        super.onDestroy();
    }
}
```

---

## ViewModels

### Design Pattern

All ViewModels follow the same pattern:

1. **Extend AndroidViewModel** to access Application
2. **Hold RfidManager reference** from Application singleton
3. **Expose LiveData** for UI observation
4. **Handle SDK callbacks** and update LiveData
5. **Provide action methods** for UI events
6. **Cleanup in onCleared()**

### 1. ScanViewModel

**File**: `viewmodels/ScanViewModel.java` (~180 lines)

**Purpose**: Manages reader scanning and connection logic

**LiveData Exposed**:

```java
private final MutableLiveData<List<RfidReader>> readers = new MutableLiveData<>();
private final MutableLiveData<Boolean> scanning = new MutableLiveData<>(false);
private final MutableLiveData<Boolean> connected = new MutableLiveData<>(false);
private final MutableLiveData<RfidError> errors = new MutableLiveData<>();
```

**Key Methods**:

```java
public void startScan() {
    readersList.clear();
    readers.setValue(readersList);

    rfidManager.startScan(new RfidScanCallback() {
        @Override
        public void onReaderDiscovered(RfidReader reader) {
            // Add to list if not already present
            if (!containsReader(reader)) {
                readersList.add(reader);
                readers.setValue(readersList);
            }
        }

        @Override
        public void onScanError(RfidError error) {
            errors.setValue(error);
            scanning.setValue(false);
        }
    });

    scanning.setValue(true);
}

public void stopScan() {
    rfidManager.stopScan();
    scanning.setValue(false);
}

public void connectToReader(RfidReader reader) {
    stopScan();

    rfidManager.connect(reader, new RfidConnectionCallback() {
        @Override
        public void onConnected(RfidReader reader) {
            connected.setValue(true);
        }

        @Override
        public void onConnectionFailed(RfidError error) {
            errors.setValue(error);
            connected.setValue(false);
        }

        @Override
        public void onDisconnected() {
            connected.setValue(false);
        }
    });
}

@Override
protected void onCleared() {
    stopScan();
}
```

### 2. InventoryViewModel

**File**: `viewmodels/InventoryViewModel.java` (~200 lines)

**Purpose**: Manages tag inventory logic

**LiveData Exposed**:

```java
private final MutableLiveData<List<RfidTag>> tags = new MutableLiveData<>();
private final MutableLiveData<RfidInventoryStats> stats = new MutableLiveData<>();
private final MutableLiveData<Boolean> inventorying = new MutableLiveData<>(false);
private final MutableLiveData<RfidError> errors = new MutableLiveData<>();
```

**Key Methods**:

```java
public void startInventory() {
    rfidManager.startInventory(new RfidInventoryCallback() {
        @Override
        public void onTagRead(RfidTag tag) {
            // Update or add tag to list
            updateTagInList(tag);
            tags.setValue(tagsList);
        }

        @Override
        public void onInventoryRound(RfidInventoryStats inventoryStats) {
            stats.setValue(inventoryStats);
        }

        @Override
        public void onInventoryStopped(RfidStopReason reason) {
            inventorying.setValue(false);
        }

        @Override
        public void onInventoryError(RfidError error) {
            errors.setValue(error);
            inventorying.setValue(false);
        }
    });

    inventorying.setValue(true);
}

public void stopInventory() {
    rfidManager.stopInventory();
    inventorying.setValue(false);
}

public void clearTags() {
    tagsList.clear();
    tags.setValue(tagsList);
    stats.setValue(null);
}

private void updateTagInList(RfidTag newTag) {
    // Find existing tag by EPC
    for (int i = 0; i < tagsList.size(); i++) {
        if (tagsList.get(i).getEpc().equals(newTag.getEpc())) {
            tagsList.set(i, newTag);  // Update existing
            return;
        }
    }
    tagsList.add(newTag);  // Add new
}

@Override
protected void onCleared() {
    stopInventory();
}
```

### 3. GeigerViewModel

**File**: `viewmodels/GeigerViewModel.java` (~140 lines)

**Purpose**: Manages Geiger search logic

**LiveData Exposed**:

```java
private final MutableLiveData<RfidGeigerStats> stats = new MutableLiveData<>();
private final MutableLiveData<Boolean> searching = new MutableLiveData<>(false);
private final MutableLiveData<RfidError> errors = new MutableLiveData<>();
```

**Key Methods**:

```java
public void startSearch(String targetEpc) {
    int memoryBank = 1; // 1=EPC, 2=TID, 3=User

    rfidManager.startGeigerSearch(targetEpc, memoryBank, new RfidGeigerCallback() {
        @Override
        public void onSearchStarted() {
            searching.setValue(true);
        }

        @Override
        public void onProximityUpdate(RfidGeigerStats geigerStats) {
            stats.setValue(geigerStats);
        }

        @Override
        public void onSearchStopped(RfidStopReason reason) {
            searching.setValue(false);
        }

        @Override
        public void onSearchError(RfidError error) {
            errors.setValue(error);
            searching.setValue(false);
        }
    });
}

public void stopSearch() {
    rfidManager.stopGeigerSearch();
    searching.setValue(false);
}

@Override
protected void onCleared() {
    stopSearch();
}
```

---

## RecyclerView Adapters

### 1. ReaderListAdapter

**File**: `adapters/ReaderListAdapter.java` (~90 lines)

**Purpose**: Display list of discovered RFID readers

**Features**:
- Shows reader name, address, RSSI
- Click listener for selection
- Uses ListAdapter with DiffUtil

**Implementation**:

```java
public class ReaderListAdapter extends ListAdapter<RfidReader, ReaderListAdapter.ViewHolder> {
    private final OnReaderClickListener clickListener;

    public interface OnReaderClickListener {
        void onReaderClick(RfidReader reader);
    }

    public ReaderListAdapter(OnReaderClickListener clickListener) {
        super(new DiffUtil.ItemCallback<RfidReader>() {
            @Override
            public boolean areItemsTheSame(RfidReader oldItem, RfidReader newItem) {
                return oldItem.getAddress().equals(newItem.getAddress());
            }

            @Override
            public boolean areContentsTheSame(RfidReader oldItem, RfidReader newItem) {
                return oldItem.equals(newItem);
            }
        });
        this.clickListener = clickListener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_reader, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        RfidReader reader = getItem(position);
        holder.bind(reader, clickListener);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView textName;
        TextView textAddress;
        TextView textRssi;

        ViewHolder(View itemView) {
            super(itemView);
            textName = itemView.findViewById(R.id.textReaderName);
            textAddress = itemView.findViewById(R.id.textReaderAddress);
            textRssi = itemView.findViewById(R.id.textReaderRssi);
        }

        void bind(RfidReader reader, OnReaderClickListener clickListener) {
            textName.setText(reader.getName());
            textAddress.setText(reader.getAddress());
            textRssi.setText(String.format("%.0f dBm", reader.getRssi()));

            itemView.setOnClickListener(v -> clickListener.onReaderClick(reader));
        }
    }
}
```

### 2. TagListAdapter

**File**: `adapters/TagListAdapter.java` (~90 lines)

**Purpose**: Display list of scanned RFID tags

**Features**:
- Shows EPC, RSSI, count
- Click listener for tag selection (navigate to Geiger)
- Uses ListAdapter with DiffUtil

**Implementation**:

```java
public class TagListAdapter extends ListAdapter<RfidTag, TagListAdapter.ViewHolder> {
    private final OnTagClickListener clickListener;

    public interface OnTagClickListener {
        void onTagClick(RfidTag tag);
    }

    public TagListAdapter(OnTagClickListener clickListener) {
        super(new DiffUtil.ItemCallback<RfidTag>() {
            @Override
            public boolean areItemsTheSame(RfidTag oldItem, RfidTag newItem) {
                return oldItem.getEpc().equals(newItem.getEpc());
            }

            @Override
            public boolean areContentsTheSame(RfidTag oldItem, RfidTag newItem) {
                return oldItem.equals(newItem);
            }
        });
        this.clickListener = clickListener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_tag, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        RfidTag tag = getItem(position);
        holder.bind(tag, clickListener);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView textEpc;
        TextView textRssi;
        TextView textCount;

        ViewHolder(View itemView) {
            super(itemView);
            textEpc = itemView.findViewById(R.id.textTagEpc);
            textRssi = itemView.findViewById(R.id.textTagRssi);
            textCount = itemView.findViewById(R.id.textTagCount);
        }

        void bind(RfidTag tag, OnTagClickListener clickListener) {
            textEpc.setText(tag.getEpc());
            textRssi.setText(String.format("%.1f dBm", tag.getRssi()));
            textCount.setText(String.valueOf(tag.getCount()));

            itemView.setOnClickListener(v -> clickListener.onTagClick(tag));
        }
    }
}
```

---

## UI Resources

### Layouts

#### activity_main.xml

```xml
<!-- Home screen with navigation buttons -->
<LinearLayout
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/textConnectionStatus"
        android:text="Not connected" />

    <Button
        android:id="@+id/btnScan"
        android:text="@string/btn_scan_readers" />

    <Button
        android:id="@+id/btnInventory"
        android:text="@string/btn_tag_inventory" />

    <Button
        android:id="@+id/btnGeiger"
        android:text="@string/btn_geiger_search" />
</LinearLayout>
```

#### activity_scan.xml

```xml
<!-- Reader scanning screen -->
<LinearLayout
    android:orientation="vertical">

    <Button
        android:id="@+id/btnScan"
        android:text="@string/btn_start_scan" />

    <RecyclerView
        android:id="@+id/recyclerViewReaders"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />
</LinearLayout>
```

#### activity_inventory.xml

```xml
<!-- Tag inventory screen -->
<LinearLayout
    android:orientation="vertical">

    <LinearLayout
        android:orientation="horizontal">

        <Button
            android:id="@+id/btnInventory"
            android:text="@string/btn_start_inventory" />

        <Button
            android:id="@+id/btnClear"
            android:text="@string/btn_clear" />
    </LinearLayout>

    <TextView
        android:id="@+id/textStats"
        android:text="@string/stats_default" />

    <TextView
        android:id="@+id/textEmpty"
        android:text="@string/no_tags_found"
        android:visibility="visible" />

    <RecyclerView
        android:id="@+id/recyclerViewTags"
        android:visibility="gone" />
</LinearLayout>
```

#### activity_geiger_search.xml

```xml
<!-- Geiger search screen -->
<LinearLayout
    android:orientation="vertical"
    android:padding="16dp">

    <EditText
        android:id="@+id/editTargetEpc"
        android:hint="@string/hint_target_epc" />

    <Button
        android:id="@+id/btnSearch"
        android:text="@string/btn_start_search" />

    <TextView
        android:text="@string/label_current_rssi" />

    <TextView
        android:id="@+id/textCurrentRssi"
        android:text="-- dBm"
        android:textSize="24sp" />

    <TextView
        android:text="@string/label_peak_rssi" />

    <TextView
        android:id="@+id/textPeakRssi"
        android:text="-- dBm" />

    <TextView
        android:text="@string/label_proximity" />

    <ProgressBar
        android:id="@+id/progressProximity"
        style="?android:attr/progressBarStyleHorizontal"
        android:max="100"
        android:progress="0" />

    <TextView
        android:id="@+id/textReadCount"
        android:text="0" />
</LinearLayout>
```

#### item_reader.xml

```xml
<!-- Reader list item -->
<LinearLayout
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/textReaderName"
        android:textSize="16sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/textReaderAddress" />

    <TextView
        android:id="@+id/textReaderRssi" />
</LinearLayout>
```

#### item_tag.xml

```xml
<!-- Tag list item -->
<LinearLayout
    android:orientation="horizontal"
    android:padding="12dp">

    <TextView
        android:id="@+id/textTagEpc"
        android:layout_weight="1" />

    <TextView
        android:id="@+id/textTagRssi"
        android:layout_width="80dp" />

    <TextView
        android:id="@+id/textTagCount"
        android:layout_width="60dp" />
</LinearLayout>
```

### Strings (values/strings.xml)

```xml
<resources>
    <string name="app_name">CS710 QuickStart</string>

    <!-- Buttons -->
    <string name="btn_scan_readers">Scan for Readers</string>
    <string name="btn_tag_inventory">Tag Inventory</string>
    <string name="btn_geiger_search">Geiger Search</string>
    <string name="btn_start_scan">Start Scan</string>
    <string name="btn_stop_scan">Stop Scan</string>
    <string name="btn_start_inventory">Start Inventory</string>
    <string name="btn_stop_inventory">Stop Inventory</string>
    <string name="btn_clear">Clear</string>
    <string name="btn_start_search">Start Search</string>
    <string name="btn_stop_search">Stop Search</string>

    <!-- Labels -->
    <string name="label_current_rssi">Current RSSI</string>
    <string name="label_peak_rssi">Peak RSSI</string>
    <string name="label_proximity">Proximity</string>

    <!-- Hints -->
    <string name="hint_target_epc">Enter target EPC</string>

    <!-- Messages -->
    <string name="no_tags_found">No tags found</string>
    <string name="stats_format">Unique: %d | Total: %d | Rate: %.1f tags/s</string>
    <string name="stats_default">Unique: 0 | Total: 0 | Rate: 0.0 tags/s</string>
    <string name="error_not_connected">Not connected to reader</string>
</resources>
```

### App Icon

**Files**: `res/mipmap-*/csl_java_logo_230510.png`

**Densities**:
- mipmap-mdpi/csl_java_logo_230510.png
- mipmap-hdpi/csl_java_logo_230510.png
- mipmap-xhdpi/csl_java_logo_230510.png
- mipmap-xxhdpi/csl_java_logo_230510.png
- mipmap-xxxhdpi/csl_java_logo_230510.png

**Manifest**:

```xml
<application
    android:icon="@mipmap/csl_java_logo_230510"
    android:roundIcon="@mipmap/csl_java_logo_230510"
    android:label="@string/app_name">
</application>
```

---

## Key Features

### 1. Connection Loading Overlay

**Feature**: UI blocking overlay during reader connection and initialization

**When**: Shown automatically during connection flow in ScanActivity

**Flow**:
1. User clicks reader → Overlay appears with "Connecting to reader..."
2. BLE connects → Message changes to "Initializing reader..."
3. Reader fully initialized (battery data available) → Overlay disappears
4. App navigates to InventoryActivity

**Timeout**: Up to 35 seconds (20s connection + 15s initialization)

**Implementation**: `ScanActivity.java:96-113`, `loading_overlay.xml`

**User Experience**:
- No UI interaction during connection
- Clear status messages
- Prevents premature operations
- Automatic navigation when ready

### 2. Battery Monitoring

**Feature**: Real-time battery level display in action bar

**Polling**: Every 5 seconds automatically

**Display**: Shows battery percentage and charging status (e.g., "Battery: 85%")

**When**: Starts automatically in `onResume()` of InventoryActivity and GeigerSearchActivity

**Implementation**: `InventoryActivity.java:175-188`

```java
@Override
protected void onResume() {
    super.onResume();
    if (rfidManager != null && rfidManager.isConnected()) {
        rfidManager.startBatteryMonitoring(batteryCallback);
    }
}

private final BatteryCallback batteryCallback = new BatteryCallback() {
    @Override
    public void onBatteryUpdate(BatteryInfo batteryInfo) {
        runOnUiThread(() -> {
            String batteryText = "Battery: " + batteryInfo.getLevel() + "%";
            if (batteryInfo.isCharging()) {
                batteryText += " (Charging)";
            }
            getSupportActionBar().setSubtitle(batteryText);
        });
    }

    @Override
    public void onBatteryError(RfidError error) {
        // Handle error silently
    }
};
```

### 3. Trigger Key Support

**Feature**: Hardware trigger button on CS710S reader controls start/stop operations

**Mode**: Manual mode (app simulates button clicks)

**Behavior**:
- **Trigger PRESS** → Clicks "Start" button (only if button shows "Start")
- **Trigger RELEASE** → Clicks "Stop" button (only if button shows "Stop")

**State Validation**: Prevents spurious actions by checking button text before clicking

**Implementation**: `InventoryActivity.java:193-210`, `GeigerSearchActivity.java:205-222`

```java
private final TriggerCallback triggerCallback = new TriggerCallback() {
    @Override
    public void onTriggerStateChanged(boolean pressed) {
        runOnUiThread(() -> {
            if (pressed) {
                // Only click if button shows "Start"
                if (btnInventory.getText().toString().equals(getString(R.string.btn_start_inventory))) {
                    btnInventory.performClick();
                }
            } else {
                // Only click if button shows "Stop"
                if (btnInventory.getText().toString().equals(getString(R.string.btn_stop_inventory))) {
                    btnInventory.performClick();
                }
            }
        });
    }
};

@Override
protected void onResume() {
    super.onResume();
    if (rfidManager != null && rfidManager.isConnected()) {
        rfidManager.enableTrigger(triggerCallback, false);  // false = manual mode
    }
}
```

**User Experience**:
- Natural hardware button control
- Same validation as soft button clicks
- Works in both Inventory and Geiger Search activities
- Prevents starting when already started, stopping when already stopped

### 4. Stats TextView Visibility Management

**Feature**: Statistics TextView only visible when inventory is running

**Behavior**:
- Hidden when not inventorying
- Visible when inventory starts
- Shows real-time stats (unique count, total reads, rate)

**Implementation**: `InventoryActivity.java:138-149`

```java
// Observe inventory state
viewModel.isInventorying().observe(this, inventorying -> {
    if (inventorying) {
        btnInventory.setText(R.string.btn_stop_inventory);
        textStats.setVisibility(View.VISIBLE);  // Show stats
    } else {
        btnInventory.setText(R.string.btn_start_inventory);
        if (textStats.getText().toString().equals(getString(R.string.stats_default))) {
            textStats.setVisibility(View.GONE);  // Hide if no data
        }
    }
});
```

### 5. Automatic Configuration

**When**: Applied automatically when InventoryActivity loads and reader is connected

**What**: Configures reader with optimal settings for inventory

**Settings**:
- Power Level: 300 (30.0 dBm)
- Session: 1
- Target: A
- Inventory Mode: COMPACT
- Q Value: 7
- Beep: Enabled
- Vibrate: Enabled
- RSSI Display: dBm mode

**Implementation**: `InventoryActivity.java:132-156`

**User Experience**:
- Configuration happens transparently
- Toast notification on success/failure
- No manual configuration needed
- Consistent reader behavior

### 6. RSSI Display in dBm

**Feature**: All RSSI values displayed as negative dBm values

**Where**:
- Reader list (ScanActivity)
- Tag list (InventoryActivity)
- Geiger search (GeigerSearchActivity)

**Format**:
- `-50.0 dBm` (one decimal place for tags)
- `-50 dBm` (no decimals for readers)

**Implementation**: SDK wrapper handles negation

### 7. CSL Logo Branding

**Feature**: CSL company logo used as app icon and splash screen

**Files**: csl_java_logo_230510.png in all mipmap densities

**Result**: Professional branding matching CSL products

### 8. Tag Click Navigation

**Feature**: Click any tag in inventory to start Geiger search

**Flow**:
1. User inventories tags
2. User clicks tag in list
3. App navigates to GeigerSearchActivity
4. Target EPC pre-filled from clicked tag
5. User can immediately start search

**Implementation**: `InventoryActivity.java:120-125`

### 9. Error Handling

**Methods**:
- Toast notifications for errors
- LiveData for error state
- User-friendly error messages
- Automatic state recovery

**Error Types Handled**:
- Connection failures
- Not connected errors
- Configuration failures
- Inventory errors
- Search errors

### 10. Empty States

**Implementation**:
- "No tags found" message when tag list is empty
- Shows RecyclerView only when tags present
- Clear visual feedback

**User Experience**:
- User knows when no data is available
- Clear indication of app state

---

## User Workflows

### Workflow 1: Scan and Connect

```
1. Launch app (MainActivity)
2. Tap "Scan for Readers"
3. Navigate to ScanActivity
4. Tap "Start Scan" button
5. Readers appear in list as discovered
6. Tap reader to connect
7. See "Connected" toast
8. Navigate back to MainActivity
9. Connection status shows "Connected: CS710-xxxxx"
```

### Workflow 2: Inventory Tags

```
1. From MainActivity, tap "Tag Inventory"
2. Navigate to InventoryActivity
3. See "Reader configured successfully" toast (auto-config)
4. Tap "Start Inventory" button
5. Tags appear in list as read
6. Stats update in real-time (unique, total, rate)
7. RSSI shows as negative values (-50.0 dBm)
8. Beep sounds on each tag read
9. Device vibrates on each tag read
10. Tap "Stop Inventory" when done
11. Tap "Clear" to remove tags
```

### Workflow 3: Locate Tag (Geiger Search)

**Option A: Direct Navigation**
```
1. From MainActivity, tap "Geiger Search"
2. Navigate to GeigerSearchActivity
3. Enter target EPC in text field
4. Tap "Start Search"
5. Move reader closer/farther from target
6. Watch RSSI update in real-time
7. Watch proximity bar fill (0-100%)
8. Bar color changes (red→orange→yellow→green)
9. Tap "Stop Search" when done
```

**Option B: From Inventory**
```
1. From InventoryActivity, tap any tag in list
2. Navigate to GeigerSearchActivity
3. Target EPC pre-filled from clicked tag
4. Tap "Start Search"
5. (same as Option A steps 5-9)
```

---

## Build and Deployment

### Requirements

- **Java 17 or higher**
- **Android Studio Giraffe or newer**
- **Android SDK API 26+** (Android 8.0+)
- **Gradle 8.13.0**

### Build Commands

```bash
# Build QuickStart app
./gradlew :cs710aquickstart:build

# Build debug APK
./gradlew :cs710aquickstart:assembleDebug

# Build release APK
./gradlew :cs710aquickstart:assembleRelease

# Install on device
./gradlew :cs710aquickstart:installDebug

# Clean build
./gradlew clean :cs710aquickstart:build
```

### APK Output

**Debug APK**: `cs710aquickstart/build/outputs/apk/debug/cs710aquickstart-debug.apk`

**Release APK**: `cs710aquickstart/build/outputs/apk/release/cs710aquickstart-release.apk`

### Installation

```bash
# Via Gradle
./gradlew :cs710aquickstart:installDebug

# Via ADB
adb install cs710aquickstart/build/outputs/apk/debug/cs710aquickstart-debug.apk

# Check if installed
adb shell pm list packages | grep cs710aquickstart
```

### Permissions

The app requests these permissions at runtime:

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location (required for BLE scanning on Android) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Runtime Permission Flow**:
1. App requests permissions in MainActivity.onCreate()
2. User sees system permission dialog
3. User grants/denies permissions
4. App checks permissions before BLE scanning

---

## Testing Guide

### Manual Testing Procedures

#### Test 1: Reader Scanning

**Prerequisites**: CS710S reader powered on and in range

**Steps**:
1. Launch app
2. Tap "Scan for Readers"
3. Tap "Start Scan"
4. Wait 3-5 seconds

**Expected Results**:
- ✅ Reader appears in list within 5 seconds
- ✅ Reader name shows "CS710-xxxxx"
- ✅ Reader address shows MAC address
- ✅ Reader RSSI shows negative value (e.g., -60 dBm)
- ✅ Multiple readers show if available

**Pass Criteria**: At least one reader discovered

#### Test 2: Reader Connection

**Prerequisites**: Reader discovered in scan list

**Steps**:
1. Tap reader in list
2. Wait for connection (max 20 seconds)

**Expected Results**:
- ✅ "Connected" toast appears
- ✅ Navigation back to MainActivity
- ✅ Connection status shows "Connected: CS710-xxxxx"
- ✅ Connection completes within 20 seconds

**Pass Criteria**: Connection successful with toast notification

#### Test 3: Auto-Configuration

**Prerequisites**: Reader connected

**Steps**:
1. From MainActivity, tap "Tag Inventory"
2. Wait for configuration

**Expected Results**:
- ✅ "Reader configured successfully" toast appears
- ✅ Toast appears within 2 seconds of page load
- ✅ No errors shown

**Pass Criteria**: Configuration toast appears

#### Test 4: Tag Inventory

**Prerequisites**: Reader connected, RFID tags in range

**Steps**:
1. On InventoryActivity, tap "Start Inventory"
2. Hold reader near RFID tags
3. Observe for 10 seconds
4. Tap "Stop Inventory"

**Expected Results**:
- ✅ Tags appear in list as read
- ✅ EPC shows as hex string
- ✅ RSSI shows negative value (e.g., -50.0 dBm)
- ✅ Count increments on multiple reads
- ✅ Statistics update (unique count, total reads, rate)
- ✅ Beep sounds on tag read
- ✅ Device vibrates on tag read
- ✅ Read rate shows 50-200 tags/sec
- ✅ Inventory stops when button tapped

**Pass Criteria**: Tags read successfully with correct data

#### Test 5: Geiger Search (Direct)

**Prerequisites**: Reader connected, know target EPC

**Steps**:
1. From MainActivity, tap "Geiger Search"
2. Enter target EPC in text field
3. Tap "Start Search"
4. Move reader toward/away from target tag
5. Observe RSSI and proximity
6. Tap "Stop Search"

**Expected Results**:
- ✅ Search starts immediately
- ✅ Current RSSI shows negative value and updates
- ✅ Peak RSSI shows highest value seen
- ✅ Proximity bar updates (0-100%)
- ✅ Bar color changes with proximity (red/orange/yellow/green)
- ✅ Read count increments
- ✅ Values update in real-time (< 1 second latency)
- ✅ Search stops when button tapped

**Pass Criteria**: RSSI and proximity track distance to tag

#### Test 6: Geiger Search (From Inventory)

**Prerequisites**: Reader connected, tags in inventory list

**Steps**:
1. On InventoryActivity, inventory tags
2. Tap any tag in list
3. Observe navigation to GeigerSearchActivity
4. Verify target EPC is pre-filled
5. Tap "Start Search"
6. (same as Test 5 steps 4-6)

**Expected Results**:
- ✅ Navigation to GeigerSearchActivity
- ✅ Target EPC field contains clicked tag's EPC
- ✅ (same as Test 5 expected results)

**Pass Criteria**: Navigation works, EPC pre-filled correctly

#### Test 7: Clear Tags

**Prerequisites**: Tags in inventory list

**Steps**:
1. On InventoryActivity, tap "Clear"
2. Observe list

**Expected Results**:
- ✅ All tags removed from list
- ✅ "No tags found" message appears
- ✅ Statistics reset to 0

**Pass Criteria**: List cleared successfully

#### Test 8: Error Handling

**Test 8a: Not Connected**

**Steps**:
1. Ensure not connected to reader
2. Tap "Tag Inventory"
3. Tap "Start Inventory"

**Expected Results**:
- ✅ "Not connected to reader" error shown

**Test 8b: Connection Lost**

**Steps**:
1. Connect to reader
2. Start inventory
3. Power off reader

**Expected Results**:
- ✅ "Connection lost during inventory" error shown
- ✅ Inventory stops automatically

**Test 8c: Configuration Failed**

**Steps**:
1. Connect to reader
2. Disconnect reader immediately
3. Navigate to inventory page

**Expected Results**:
- ✅ "Configuration failed" error shown

**Pass Criteria**: All error scenarios handled gracefully

### Performance Testing

#### Inventory Performance

**Metrics to Measure**:
- Read rate (tags per second)
- UI responsiveness during inventory
- Memory usage over 5 minutes
- Battery drain rate

**Expected Performance**:
- Read rate: 100-300 tags/sec (depends on tag count and signal)
- UI: Smooth scrolling, no lag
- Memory: Stable, no leaks
- Battery: Moderate drain (< 10%/hour)

#### Connection Performance

**Metrics to Measure**:
- Time to discover reader
- Time to connect
- Connection stability

**Expected Performance**:
- Discovery: < 5 seconds
- Connection: < 20 seconds
- Stability: No disconnects during normal use

---

## Known Issues and Limitations

### Limitations

1. **Single Reader**: Only supports one connected reader at a time
2. **BLE Only**: No USB or Wi-Fi connection support
3. **Android 8.0+**: Requires API 26 or higher
4. **No Persistence**: Tag list cleared when app closes
5. **No Export**: Cannot export tag list to file

### Known Issues

None currently reported.

---

## Future Enhancements

### Potential Features

1. **Tag History**: Persist tag reads across sessions
2. **Data Export**: Export tag list to CSV/JSON
3. **Tag Filtering**: Filter by EPC pattern, RSSI threshold
4. **Multi-Reader**: Support multiple simultaneous readers
5. **Settings Screen**: Configure default power, session, etc.
6. **Tag Details**: Detailed view for each tag
7. **Read/Write**: Tag memory read/write operations
8. **Batch Operations**: Bulk tag operations
9. **Custom Beep**: Different sounds for different RSSI ranges
10. **Dark Mode**: Dark theme support

### Architecture Improvements

1. **Repository Pattern**: Add data layer with Room database
2. **Dependency Injection**: Use Hilt for DI
3. **Navigation Component**: Use Jetpack Navigation
4. **Jetpack Compose**: Migrate UI to Compose
5. **Coroutines/Flow**: Replace callbacks with Flow

---

## Conclusion

The **CS710 QuickStart** app provides a complete, production-ready Android application demonstrating RFID operations with the CSL CS710S reader. Key features:

✅ **Complete Workflows**: Scan, connect, inventory, Geiger search with loading overlay
✅ **MVVM Architecture**: Clean, testable, maintainable code
✅ **Modern Android**: LiveData, ViewModel, RecyclerView, Material Design
✅ **Hardware Integration**: Battery monitoring, trigger key support
✅ **Production Quality**: Error handling, auto-configuration, branding, state management
✅ **User Friendly**: Intuitive UI, real-time updates, clear feedback, hardware button control

**New in v2.0**:
- Connection loading overlay with initialization status
- Real-time battery monitoring (5-second polling)
- Hardware trigger key support (manual mode with state validation)
- Stats TextView visibility management
- Enhanced connection flow (CONNECTING → INITIALIZING → READY)

**Status**: ✅ **PRODUCTION READY**

---

**Document Version**: 2.0.0
**Last Updated**: January 2025
**Total Lines of Code**: ~1,850 lines
**Total Files**: 10 Java files + 7 XML layouts
