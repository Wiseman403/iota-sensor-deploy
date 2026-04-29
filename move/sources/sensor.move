module sensor_package::sensor {

    /// Represents a single sensor reading.
    public struct SensorData has key, store {
        id: UID,
        temperature: u64,
        humidity: u64,
    }

    /// Represents the hub or origin of sensor data.
    public struct SensorHub has key {
        id: UID,
        readings_recorded: u64,
    }

    /// Initializes the SensorHub and transfers ownership to the publisher.
    /// Runs automatically when the package is published.
    fun init(ctx: &mut TxContext) {
        let hub = SensorHub { id: object::new(ctx), readings_recorded: 0 };
        transfer::transfer(hub, tx_context::sender(ctx));
    }

    /// Records a new sensor reading; increments the hub counter; returns the new SensorData.
    public fun new_sensor_reading(
        hub: &mut SensorHub,
        temperature: u64,
        humidity: u64,
        ctx: &mut TxContext,
    ): SensorData {
        hub.readings_recorded = hub.readings_recorded + 1;
        SensorData { id: object::new(ctx), temperature, humidity }
    }

    public fun temperature(self: &SensorData): u64 { self.temperature }
    public fun humidity(self: &SensorData): u64 { self.humidity }
    public fun readings_recorded(self: &SensorHub): u64 { self.readings_recorded }
}
