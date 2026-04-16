# GTO Loadouts

Arma 3 Loadout-Dateien fuer German Tactical Ops.

## Aktueller Stand

### Basis-Standard (Base_Rifleman)

Alle aktualisierten Loadouts basieren auf dem **Base_Rifleman** Standard:

**Waffe:** MCC M4A1 (`MCC_M4A1_556_URGI`) mit MCC Attachments
- Suppressor: `MCC_RC2_556_FDE`
- Laser/Light: `MCC_AR_PEQ15_M300C_Tail_FDE_IRL`
- Optic: `rhsusf_acc_su230_3d`
- Magazin: `rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan`
- Ersatz-Magazine (Vest/Backpack): `MCC_PMAG_556_FDE_556_30_M855A1`

**Uniform (Medic-Items):**
| Item | Anzahl |
|---|---|
| ACE_tourniquet | 4 |
| ACM_PressureBandage | 35 (bzw. reduziert bei Extras) |
| ACM_ChestSeal | 2 |
| ACM_EmergencyTraumaDressing | 2 |
| ACE_CableTie | 3 |
| ACE_EarPlugs | 1 |
| ACE_IR_Strobe_Item | 1 |
| ACE_Flashlight_XL50 | 1 |
| ACM_Paracetamol | 1 |

**Vest (neue Items):**
- `ACE_salineIV_500` x3
- `ItemAndroid` x1 (aus Uniform verschoben)
- `rhsusf_mag_17Rnd_9x19_JHP` x1 (aus Uniform verschoben, nur bei Loadouts mit Pistole)

### Bereits aktualisiert

| Loadout | Waffe | Bandagen | Besonderheit |
|---|---|---|---|
| Base_Rifleman | MCC | 35 | Basis-Standard |
| Ammo_Carrier | MCC | 35 | |
| EOD | MCC | 35 | |
| Grenadier | MCC | 35 | M320 statt Pistole |
| HAT | MCC | 35 | |
| JTAC | MCC | 29 | Extra: MapTools, microDAGR, PlottingBoard, notepad |
| Junior_Medic | MCC | 35 | |
| Platoon_Leader | MCC | 33 | Extra: MapTools |
| Platoon_Medic | MCC | 35 | |
| SL | MCC | 33 | Extra: MapTools |
| Squad-Medic_ARFR | MCC | 35 | |

### Noch manuell anzupassen

Diese Loadouts haben andere Waffensysteme und muessen manuell auf den neuen Medic/Uniform/Vest-Standard gebracht werden:

| Loadout | Aktuelle Waffe | Grund |
|---|---|---|
| LMG | rhs_weap_m249_light_S | Andere Waffe (M249) |
| MMG | rhs_weap_m240G | Andere Waffe (M240) |
| Marksman_SCAR-H | rhs_weap_SCARH_FDE_STD | Andere Waffe (SCAR-H) |
| Sniper | rhs_weap_M107_w | Andere Waffe (M107) |
| Spotter_DMR | rhs_weap_sr25_ec | Andere Waffe (SR-25) |
| Helicopter_Pilot | rhs_weap_m4a1_carryhandle | Andere Waffe + Uniform (TPW_L9) |
| Jet_Pilot | - (nur Pistole) | Andere Uniform (U_B_PilotCoveralls), keine Vest |

## Skripte

- **`update_uniform_items.ps1`** - Aelteres Skript zum Austausch von Uniform-Items (ACE -> ACM)
- **`update_to_base_standard.ps1`** - Aktuelles Skript: Bringt Loadouts auf Base_Rifleman Standard (Uniform, Vest, Waffe M4/MK18 -> MCC)
