# bcc-water

**bcc-water** is a comprehensive script for managing water interactions in a RedM. It allows players to carry, drink, and refill a canteen, as well as interact with various water sources. This script integrates seamlessly with multiple metabolism systems and enhances the player experience by adding realistic water-related activities.

## Features

- **Hydration Management**: Carry a canteen of water to drink and quench thirst.
- **Multi-Use Canteen**: Drink multiple times from a full canteen, with configurable usage limits.
- **Metabolism Integration**: Compatible with various metabolism scripts to manage thirst levels.
- **Water Source Interactions**:
  - Refill canteens, buckets and bottles at water pumps, sinks, rivers, and lakes.
  - Drink directly from natural water sources to preserve canteen water.
- **Health and Stamina Configurations**: Separate settings for drinking from canteens and wild waters.
- **Hygiene Options**: Players can wash in rivers, lakes, and at water pumps or sinks.
- **Risk Factor**: Players may take damage from drinking untreated wild water.
- **Utility**: Fill water buckets and bottles for use in other scripts.

## Dependencies

- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)
- [feather-menu](https://github.com/FeatherFramework/feather-menu/releases/tag/1.2.0)

## Supported Metabolism Scripts

- VORP Metabolism
- Fred Metabolism
- Outsider Needs Metabolism
- RSD Metabolism
- NXT Metabolism
- Andrade Metabolism
- FX-HUD

## Installation

1. **Add Script to Resources**: Place the `bcc-water` folder in your resources directory.
2. **Update `server.cfg`**: Add `ensure bcc-water` to your `server.cfg` file.
3. **Script Load Order**: Ensure this script is loaded after your metabolism script and other dependencies.
4. **Database Setup**: Run the included `water.sql` file to add necessary items to your database.
5. **Image Integration**: Copy images from the `img` folder to `...\vorp_inventory\html\img\items`.
6. **Store/Crafting Setup**: Add items to a store or crafting station for player access.
7. **Configuration**: Set your metabolism script in the `config/main.lua` file.
8. **Restart Server**: Restart your server to apply the changes.

## Inspiration

- **green_canteen**: This script draws inspiration from the green_canteen script.

## GitHub Repository

- [bcc-water](https://github.com/BryceCanyonCounty/bcc-water)
