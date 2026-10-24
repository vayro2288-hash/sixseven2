if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LOADER_URL = "https://flowauth.net/v1/loaders/%s.lua"

-- One row per game. `places` = PlaceIds (checked first), `universes` = GameIds (covers every subplace).
-- All universe ids verified against games.roblox.com on 2026-10-07.
local GAMES = {
    { name = "Evade", id = "92e5ad94cecd5d7d5b2bce2d9dbdb8f7", places = { 9872472334 }, universes = { 3647333358 } },
}
local UNIVERSAL_LOADER = {
    name = "Snowy Universal",
    url = LOADER_URL:format("2cca729b34801cf2796d99b5e5625e4b"),
    universal = true,
}

local LOADERS_BY_PLACE = {}
local LOADERS_BY_GAME = {}

-- several scripts can claim the same id; keep all of them so the player can switch
local function registerLoader(map, kind, id, entry)
    local list = map[id]
    if not list then
        list = {}
        map[id] = list
    end
    if not table.find(list, entry) then
        table.insert(list, entry)
    end
end

-- Rows whose FlowAuth script is a placeholder (37-line stub calling Library:CreateWindow, created in the
-- 16 Oct 2026 batch) or no longer exists. They are skipped so those games fall back to Snowy Universal
-- instead of crashing. Delete an id from this set once its game gets a real script.
local PLACEHOLDER_IDS = {
    ["9b1244b32ff8e85904f9ed0e477595f9"] = true, -- +1 Anime Loot Upgrade
    ["7245bf386c57c94e47fef4fc62e3c001"] = true, -- +1 Aura Per Click
    ["54c71a46b3d1df7d7683444f031316b1"] = true, -- +1 Backflip Keyboard Escape
    ["08aed83623a4c73e1f2e5127b25cade6"] = true, -- +1 Banana Monkey Destruction
    ["8e74e0f372b591f6dc62d19507041015"] = true, -- +1 Chop Trees for Treasure
    ["a703ed459fb9846084d7a4af710e7ca4"] = true, -- +1 Clone Evolution
    ["2ee72103cdd149dddfc737e39549106e"] = true, -- +1 Cut and Ride Pet
    ["bf734e687acbc2074476c013c795d5fb"] = true, -- +1 Dino Evolution
    ["2bdd46d1c61c563a8f45b21e98f9661f"] = true, -- +1 DMG Per Revive
    ["c7a437f1969f6298a741ce019cee805b"] = true, -- +1 DMGFPS
    ["809fe7b615ba15f74b626f418e8f5fda"] = true, -- +1 Double Jump Bike Escape
    ["bdd608de4aff99986f7c1347f4460279"] = true, -- +1 Drain Water Per Click
    ["90d2bd89c33ad20db4c9c35ee0f82fe5"] = true, -- +1 Drill Blocks for Animals
    ["034f352e257a907454dcfde1977eeb1d"] = true, -- +1 Fart to Break Doors
    ["e08372925c30e7a69ae758f71378b567"] = true, -- +1 Fat Per Click
    ["6c0bad153fab8e0a4a3d931498133c9f"] = true, -- +1 Fish Per Click
    ["adfdf2631493a8814c13cf3bc6d18645"] = true, -- +1 Followers Per Click
    ["f8b1f8214f34e3daf1171b73ad7a9482"] = true, -- +1 Football for Brainrots
    ["3f51a21ddafd32f02e8b4ad1ae36a461"] = true, -- +1 Fruit Samurai
    ["b56d1cca3fe769d8e0c8c990eb44e124"] = true, -- +1 Hack Per Click
    ["1d7566d3ee5b583f9d0546e7c8e91b5e"] = true, -- +1 Heat Per Click
    ["ca54b02e167c95359543e30d0422b21f"] = true, -- +1 Height Per Jump
    ["b68c0d81a2a23f661802b6db135c84ac"] = true, -- +1 Horse Evolution
    ["54fb8a601e65f82c537f01bbc9a889f1"] = true, -- +1 Jump Crunchy ASMR Escape
    ["1389736fe27d0916fb1b66f0f74b2743"] = true, -- +1 Kitten Keyboard Escape
    ["c28b71e9e5dbed13207d28b4c8225de4"] = true, -- +1 Lava Escape
    ["633a2db72ae9b9a7f9d7d86b5a4caa2c"] = true, -- +1 Long Arm Toy Escape
    ["81558598569efa4dc77d4d9b38c73f7a"] = true, -- +1 Mog Evolution
    ["a496febed94d07457b1bd9c91ab2c4c2"] = true, -- +1 Muscle Evolution
    ["960154d614b59a9508a46e8152137a8a"] = true, -- +1 Muscles for Prison Escape
    ["3e377560fa9f8c7e90d2b04bbc31f3b2"] = true, -- +1 Pickaxe Swing Escape
    ["90c8c32374637d6bafa09a3a22ba2136"] = true, -- +1 Poop Per Click
    ["d6a6337ef40b19b32a15d66f63507d5e"] = true, -- +1 Poor to Rich
    ["22fd489f7bb71b94396be5dac44b88ff"] = true, -- +1 Power Jujutsu Kaisen Evolution
    ["c24bfe76cde36c0311b1259820a9751a"] = true, -- +1 Power Per Click
    ["e79eada3dd1e09f320f9a238167f9b14"] = true, -- +1 Shrinkper Step
    ["90ece109757b67696757e8f56522983e"] = true, -- +1 Skinny Per Step
    ["ab77468fc1ea8df652aa3c483675f5bc"] = true, -- +1 Slash Per Click
    ["17e6da1ce4c80ec31100357b3f912379"] = true, -- +1 SMASH Walls for Anime Characters
    ["19d05c4701c09172d1be8eae3eaa2327"] = true, -- +1 Speed Evolve
    ["3dfe61b83605da94e56d15bcea1c3dc8"] = true, -- +1 Speed Ninja Keyboard Escape
    ["ee433a471248bf6058bd10b6d2706400"] = true, -- +1 Speed Plane Escape
    ["c168f2a901df0eebca548e1284f08c3b"] = true, -- +1 Speed Squirrel Escape
    ["3b0c5948edb374fa3ddaf9e093662204"] = true, -- +1 Speedster Escape
    ["551d8239ae04d5afa224e518ef5dfef0"] = true, -- +1 Spider Evolution
    ["c0f02a9cff5f9a0ac5651f7df9ad9283"] = true, -- +1 Spinjitsu Escape
    ["06d3449e9f724d4c24a8c24ac0ee4c2c"] = true, -- +1 St and Power Evolution
    ["42c2422c6ab0c38b971aaef3aeb48dfc"] = true, -- +1 Strength for Eggs
    ["b63b67f5836d1649cd2a22c35cee107e"] = true, -- +1 Strength to Grow Your Arm
    ["049877bfb1168ad350b04e16168570f7"] = true, -- +1 Superhero Evolution
    ["5b1992c0496759e06fa5db94734602e7"] = true, -- +1 Sword Fighting Escape
    ["dc93c4d9d4449ad6defb03b3f4af7428"] = true, -- +1 Swordvs Anime
    ["d2279d5374cc085500947816a9b0c2a8"] = true, -- +1 Tall to Escape
    ["524359be708cfcbd750759938f57a4dc"] = true, -- +1 TNT Mining
    ["7f8c06422fe01e41e2aa44b46f65b96b"] = true, -- +1 Web Swing Escape
    ["8d25d9e62739828e55e24f3e9e46048c"] = true, -- +1 Weight Escape
    ["50d3db73553ec142362bcc44826a841b"] = true, -- +1 Wings for Brainrots
    ["00a882a7e8e973bfb5791f02ca68b8fb"] = true, -- 50 Player BINGO
    ["81e67870a3a5ebb0e16d260df1775af1"] = true, -- Age Evolution Tycoon
    ["9b2fe701640b584608a85af9431bb4ec"] = true, -- Airport Tycoon
    ["8b39f677d1ad8fec6b026171d48da8e3"] = true, -- Anime Astral Simulator
    ["eeb46840d4509bb386f8776bc40466ac"] = true, -- Anime Battle RNG
    ["d9dc442ce1fef0131a393273093c3cf3"] = true, -- Anime Card Farm
    ["c10518f616d4d922f246503ba8be7337"] = true, -- Anime Girl Paintby Numbers
    ["87ef79d117d4c0df51f105b279b22e7e"] = true, -- Anime Jackpot
    ["4146ace756a49c3c8b52bce4ab3967b6"] = true, -- Anime Overseer
    ["0e2e0ff9348e6be1648a6afb5fff92d7"] = true, -- Anime RNG
    ["f5df02ac5fd620fc1b5539ff6534b718"] = true, -- Anime RNG Defense
    ["1dbfd66228abd2d6e75dda5891959717"] = true, -- Anime Souls
    ["1afd22a852fe7b66cfb8f835a00f97e8"] = true, -- Anime Squadron
    ["0a8c712f9552adec978d71512e2d2117"] = true, -- Anime Story2 the Final Novel
    ["230e104c39f6a4ba12b432e7e59e0ab9"] = true, -- Anime Ultron Simulator
    ["b119479a429f64682da04458e572c0a1"] = true, -- Anime War RNG
    ["5abe40b73ea1fb2e972e507e2cdd4da0"] = true, -- Anomaly Garden
    ["d7f3b361730a98a69935729229880a74"] = true, -- Aura for Brainrots
    ["056fe7f674355082a6681570a4d18a99"] = true, -- Automate a Restaurant
    ["db862706c9748649e988efaeedf58595"] = true, -- Axe RNG
    ["5a4e400c077f152e399bce7eeac311ca"] = true, -- Backflip for Animals
    ["1944e3b618fe4cf3b10561556f7ecbe5"] = true, -- Backrooms Simulator
    ["0e247fc332d9b3c5e3337638c4fa0162"] = true, -- Basketball Dynasty
    ["493e6352030945476337991eb3486d5d"] = true, -- Be a Fish Bait (Sci-Fi Update)
    ["45124961f449a7c4bec2d937e2c0b78f"] = true, -- Be Monkey for Brainrots
    ["8f928e3a948eb753a55bbd3a652fe82c"] = true, -- Be the Final Boss
    ["4fc84c4cfefc3ea91a2ccdeb6a733524"] = true, -- Beat the Anime Boss
    ["cc17171f5a3af67852e6a401f14ac057"] = true, -- Becomea Billionaire
    ["5ea39069e89707f51384df42d47b0d58"] = true, -- Bee Re Masters
    ["669f03ba41402d3f52f5f46439d96c16"] = true, -- Bid for Anime
    ["98e96de04de3bc88896ccce56f51dc39"] = true, -- Bid for Soccer Cards
    ["349a24658be8f5b529543c5d684fa80e"] = true, -- Blowup Lucky Blocks for Cars
    ["7b72c6f7e6b144b8210f0708265765b5"] = true, -- Bomb Fishing
    ["7e6a004806f93be64fbb8afeb4a0e2a9"] = true, -- Brainrot Card Battles
    ["3274b1a7cbd1f6af8de4fcb478ec653b"] = true, -- Brainrot Sniper
    ["235997e37a585ddaf067ff055d90a681"] = true, -- Break Door
    ["44260765fec0ddf039e78f8487af5fe2"] = true, -- Break for Anime
    ["8db697e5e07ba76b8cb56f60b574a76e"] = true, -- Break Tape for Brainrots
    ["e390fb8b5b4dd964b2b54a61d8d13ada"] = true, -- Break Walls for Brainrots
    ["28defa90700c43cdbe12a5b97f3ba95f"] = true, -- Breakan Egg
    ["51610c042ab05780c054b4e5567c0c7f"] = true, -- BUIL Dyour Butterfly Garden
    ["95c9fdad3696169be448ce35c6015b1a"] = true, -- Build a Base and Steal
    ["2102128131b70d4952415705e4e85938"] = true, -- Build a Bee Swarm
    ["cb314e829b2619b4bfb5ccd55cdba04f"] = true, -- Build a Burger
    ["e1a18dbc6f8a23e3b9272d8855ad5534"] = true, -- Build a Cart
    ["7aee7282bca89e86ffa1e8301feab70e"] = true, -- Build a Clone Obby
    ["ee41499394bd356ccedc5b8b7a1d8a85"] = true, -- Build a Garden Tower
    ["eb7228bc09d2964e40efc23048d5485f"] = true, -- Build a Golem
    ["fa927dbdb511c791914d9854823f1bce"] = true, -- Build a Gun Army
    ["8f27c8953c6b956616e5f1648c6555fd"] = true, -- Build a Keyboard
    ["c2e3f358f6ca9169865e641ca3ba839c"] = true, -- Build a Pet Factory
    ["4ce151031f5566260b6794ea1ff2c078"] = true, -- Build a Phone Empire
    ["22a143286c988c712faa0aab1504144a"] = true, -- Build a Solar Farm
    ["e541b4d76b831a2dda2d5c972c20c3c5"] = true, -- Build a Zoo
    ["e2b1ac9d8e28bc05831af51d59652342"] = true, -- Build an Ore Farm
    ["35c04f993a43586032c98cbad85224ec"] = true, -- Build Base to Survive VERITY
    ["526eaa27da91e839827d66bfe3d74c55"] = true, -- Build Golems and Fight
    ["90aec04e309802945816d83133c116eb"] = true, -- Buildan AI
    ["7922c5660c84534070dbe36d243b24b0"] = true, -- Burgir Incremental
    ["5501dcafc6266e8366ed318d6fc5128d"] = true, -- Cake Mountain
    ["a2534571960ce8b88f94122768f7bb90"] = true, -- Capybaras VS Plants
    ["b9c5bfa0134726a794715b887327f24e"] = true, -- Cars VS Tape
    ["a6b6d41e52e719236b79056319379596"] = true, -- Carve Wood
    ["8455798e9ca526d827ac020fe071b717"] = true, -- Case Paradise
    ["4b4de49eb2bfb901ebf6d09aa790370f"] = true, -- Catch a Billion Ducks
    ["e6669bc2f91b8f485e617200c8d340d0"] = true, -- Catch and Tame
    ["74c52c5091ccaf4a0e56b315d1aa4dbc"] = true, -- Catch Dragons to Defend
    ["743b10a60a6a66c852079c41c44b9ccd"] = true, -- Catch1 Billion Ducks
    ["e7684c7eb56f2d4ae6e7e274bf206bd1"] = true, -- Catcha Monster
    ["3a0756e539f7d40690c556ea4f23e914"] = true, -- Chicken Farm
    ["be8eed9f4e5b1a5a13fbb4f87e34270d"] = true, -- Choose the Stronger Anime
    ["974acec47e9504b3993ee73d5f94b46a"] = true, -- Claw Fishing
    ["dc75e9439276e5e376bb86c6f3e40a4f"] = true, -- Clean the WORLD
    ["bf8757a58347c62df87479f05cba9d2a"] = true, -- Clean Your Keycaps
    ["fb59d815e8e06b20c7925a9f74247885"] = true, -- Clicker Simulator
    ["3cb701f62bea8fea367d646098bc9cd9"] = true, -- Cliff Mansion Tycoon
    ["6569b4261e0bd1a030b42b89907dd9fc"] = true, -- Climb and Dropa Lucky Block
    ["dbfa2dda6ecfda14e3b4a40554d5fb8c"] = true, -- Climb Waterslide and Slide
    ["bb5bfdef525380fd43eb34acd24238af"] = true, -- Clone to Steal Eggs
    ["546c87d6aee6b6426aa5772724d25ee3"] = true, -- Coacha Fighter
    ["52c5403d1d884046ff8e358a718a1fdf"] = true, -- Coin Flip
    ["2a3c0104e3b3d600d164e7e5e982eb13"] = true, -- Collect Cars and Race
    ["9e39bb71b059c43cf2d3ad3a7dae7daf"] = true, -- Collect the Alphabet
    ["c2bb1a9c1d51cb8d4429312f4a31928d"] = true, -- Collect1 Million Items
    ["ff9d3bb3ef730e0bb8c67e6d59242236"] = true, -- Cook Sell
    ["432e8948fd6e186eb5452d38861956a5"] = true, -- Cowboy DUELS
    ["b233a11f1718884422fe18b5633cda9d"] = true, -- Cows RNG
    ["9d85635547c1c2463a892aee1acbbdc5"] = true, -- Cultivation Evermortal
    ["8f5fbed381452988870fa59952744b8d"] = true, -- Cuta Gem
    ["25a688c0f647ce8ad95d4b915cb6eca4"] = true, -- Death Order Simon Says
    ["b15eae548cdd5b206e22040b848e8d73"] = true, -- Defeat Anime RNG
    ["a707b03cc7a7baae2f75eae459d881b1"] = true, -- Defend Your Animals
    ["7c1a2ff4b0e1db571c7f37e60812bf70"] = true, -- Defend Your Base with Anime
    ["325fd01512af57fc7ec9eefedd39c428"] = true, -- Defend Your Plushie TD
    ["f3ad5dbf7efcea048b5f933d2c6d5114"] = true, -- Defend Your Treehouse
    ["b76f11f3fc741fd3f984076c988349d5"] = true, -- Defendmy Ring Farm
    ["33cb886a7475884162b0ad687e927b0a"] = true, -- Destroya House
    ["a6f2fbdd8c6a9689b924027a0fb7d314"] = true, -- Dig in to Secrets
    ["e78ee9c4ac5a25e21b0dd3370fc8bf12"] = true, -- Dino Hunters
    ["feba66c9c9847f957aa7532adf52f4b6"] = true, -- Dont Steal the Bobo
    ["aaa865467d81265ba3f959080d9e674c"] = true, -- Dragon Adventures
    ["5b71d38b93124a4d498ef5ba1578f07e"] = true, -- Dream Car Collection
    ["81e13f8d5458d53c03456165ff6e40d7"] = true, -- Dream Keyboard Escape
    ["56dab53daa99e35fb710de06cde9a73f"] = true, -- Drill Blocks for Brainrots
    ["1fd44c17a4d9a262133f32fa4a473f92"] = true, -- Drill for Anime
    ["e820b44dc21545287d6ecd5ddfdaba19"] = true, -- Drive Thru Empire
    ["0bf314fcfd05e7d100deaef8e1733c7a"] = true, -- Dungeon Lootr
    ["7eab130d5e584cd9dbf7cb1bc0b60aae"] = true, -- Dungeon Quest Reborn
    ["54ea43bbd2b998f7a0b129f5669d45b2"] = true, -- Elemental Magic Arena
    ["8619a75123f7a2f8def23bc20e7dc544"] = true, -- Endless Tower Defense
    ["1c48b1d0e79e7be77e55801afedc2a38"] = true, -- Evomon
    ["99b1a97e17f49b88a68f7b606e41a583"] = true, -- Farm RNG
    ["231114fd11738043881996141d0e4bac"] = true, -- Farma Fish
    ["ff6edcbadce5d92477ba7cfbbecb4951"] = true, -- Farman Island
    ["182527b287229b893caf214c6edaa94a"] = true, -- Farmers Market
    ["05fddd32e2fffe9ea0048568084ce09f"] = true, -- Fill Water Tanks
    ["a2e5895b690474eaec9a2f66b332c838"] = true, -- Final Swarm
    ["13e351f5c324a1aa3f9fc6e98620e82e"] = true, -- Fish an Anime RNG
    ["61ca77d867b987feedc3453f097e53b3"] = true, -- Fish an Egg from Rivers
    ["33c349e8595119f3057ea67d078b0bfd"] = true, -- Fish for Junk
    ["4e4cc97309c483656b2ab54b107e801c"] = true, -- Fishing Chef
    ["8e267520c0c661bdf8cd60989eba8548"] = true, -- Fishing Wars
    ["83f1d2142c384b39fb889efd40085941"] = true, -- Floppa2
    ["ee365257cd33f565caad6775925ea824"] = true, -- Forge and Sell
    ["9a0a5f7527e82b517c43188d4db8ad82"] = true, -- Forsaken
    ["837431ba6d3b45f88e247110a978ff11"] = true, -- Fruit Zombie Survival
    ["40301d8abaf31f04d0b543247c9adf81"] = true, -- Garden Cleaner Evolution
    ["5b8e9143b682ae534e3bb0f902669d5f"] = true, -- Garden Horizons
    ["b78fea1997f70ea7c6115a58ef90647a"] = true, -- Get Fat to Break Tape
    ["75d411a6871aaec9f4ce5967a782d964"] = true, -- Greedy Brainrots
    ["d6eb0763a2602d8bd7bd14aa6d5451f7"] = true, -- Greedy Growers
    ["fdce817535f725251148d03d9e201132"] = true, -- Grow It RNG
    ["a07f0d9ff276c80eca04694079c3720b"] = true, -- Growa Beehive
    ["9c47f50b1ce3c8e23a7909afbe14248c"] = true, -- Hack a Business
    ["52b3ae43884d1b1ae3c3f197a5d2ebfe"] = true, -- Hatch and Fry
    ["bc9540c95a54004879e2864118afbbed"] = true, -- Heroes RNG
    ["459480950fb29982a73246e03f30d83a"] = true, -- Hita Golf Ball
    ["623bd4568ac992db2d74ed6fda8100a9"] = true, -- Hole Fishing
    ["69282fea3a64ca716b2c7936d57f3c38"] = true, -- Hoodrivals
    ["695f2572de2fbf02274ba6948e73f765"] = true, -- Hotel Tycoon
    ["3ac3adfc19792ee3c42fdd6c0e309812"] = true, -- Hunting Season
    ["0221c01e7fbb65eddbfd791b7a4d6a25"] = true, -- Idle Mafia Game
    ["99f3dc77dac32186a4301852bb63bf6c"] = true, -- Ivory Rivals
    ["e32d98ae34654ab685f2b6ba8f551558"] = true, -- Jailbird
    ["93aaca84d1ae947040bff611e52a124d"] = true, -- Jump Beanstalk for Brainrots
    ["96374acf9733ca24a43fbf873dc229d2"] = true, -- Jump to Steal an Egg
    ["23be69f09bb138ee2e045c476517a9dd"] = true, -- Jump to Steal SCP Monsters
    ["024d80aa1fb6d94c36f412967fc44a18"] = true, -- Jump to Steal Slime
    ["f053b6d9cf9523c0a6ea3cfaad91f657"] = true, -- Jump to Steal Soccer Players
    ["ab14d452d6df141d1ffb040beba26a5d"] = true, -- Jumping Baddies
    ["2f3d154ded87e0232c46535d9c7cff01"] = true, -- Karinderya
    ["3c5ea9a1d633c9874b2a017662a64dee"] = true, -- Kawaii Anime RNG
    ["c5f96e162f38830fee50bcbe7a145220"] = true, -- Kick Ball to Space
    ["d01efce8e7c5981839d79e35acdd3245"] = true, -- Kickan Uma
    ["7abb152d760366bfc2085e2ae18a6cef"] = true, -- Lake Sipping
    ["d1c7fd61392f5a7f7bb58188f8a16db2"] = true, -- Last Stop
    ["9ce4482e0359f2d0e7765b4ce14490e9"] = true, -- Launch a Nuke
    ["c8fc991fec09214b6cfcd8d0cc6fa1c4"] = true, -- Launcha Wheel
    ["926232b2afe050092ed744c847febae8"] = true, -- Legends of Speed
    ["1d0fda88863ca77111ba5c21f0088578"] = true, -- Lifta Cube
    ["7b21a450b771dee5b5f2aa4426f93a01"] = true, -- Load the Truck
    ["e94ef79ed9aa81292c3eabe5692f7c4a"] = true, -- Loot Evo
    ["effe8696d9ea4eac535b22c6db8e2781"] = true, -- Loot RNG
    ["1b7c9938b582a6add0904a8b401f5567"] = true, -- Loot Up
    ["30defa5935e7710c89a7265341fac926"] = true, -- Lowball
    ["a34cd3a39dd67cfb978261ca06e1d57e"] = true, -- Lucky Block Rush
    ["ea3ee5a87831e837b619cf1e9592d346"] = true, -- Magnet Fishing
    ["49317c90ad293b8aca85a4586cb36519"] = true, -- Make Hotsauce
    ["3a1e583e0d952dddc9c85ad5dd06f2ed"] = true, -- Make Soccer Players
    ["a1ce068d8d2b5fd733fbace4bc622cd7"] = true, -- Makea Drill Farm
    ["1e6cc6d35f17e79603ce6f7fc74b90b3"] = true, -- Mansion Tycoon
    ["a29d1af6aaa0122284dad96c3ff25c62"] = true, -- Melt the Ice
    ["fd69e9b44f402bf1e899c7de6b9f1664"] = true, -- Merge a Spinner
    ["80726fed6987cfbcfc79347b4cf4a924"] = true, -- Merge Anime Defender
    ["758233634a051025ace1f090c2cea777"] = true, -- Merge Dig Simulator
    ["d909d99da276352c3b0a86a994d4482a"] = true, -- Merge Hackers
    ["d141d5057580b4864c9218266f948862"] = true, -- Merge Plantsvs Mobs
    ["5f11fd1b5358fc465d567057a4c5a98c"] = true, -- Merge Swords and Kill Zombies
    ["1f8c5404d794b239e8d444f06c124c85"] = true, -- Merge VS Mobs
    ["fd1c6150f7f4600a082840c0f7f33c14"] = true, -- Mergea Black Hole
    ["84602bba24e69bd977cc0667fff8af30"] = true, -- Mergea Dino
    ["b96014eba936cf1b5776c8f6490e3e9f"] = true, -- Mergea Mini Army
    ["e77801c997c6b9a58fe9eedd88ebe33e"] = true, -- Mergea Mob
    ["c95d4a5bafff434167239a507bb019e8"] = true, -- Mergea Nuke
    ["30965d919f4c2a3d8c613ea6489daf9d"] = true, -- Mergea Squishy
    ["c7c305ad8f718038cc3724b40c4da9bf"] = true, -- Mergea Tank
    ["31ef43e1b246d3ce917fab3d5a53158a"] = true, -- Mergean SCP
    ["2a377e0c1b55f643207ac4ce8ecad63b"] = true, -- Mine RNG
    ["7551f5cf17aca8001ebf9e9bd05f7843"] = true, -- Missilesvs Cities
    ["18bac4b93f33a58516ccdc172b1f2a87"] = true, -- Motorcycle for Animals
    ["afacf819312f4c9349f701b928f89090"] = true, -- Mutant Plants Base Defense
    ["3bddf27ff96667b9051bbbcc7894f2f0"] = true, -- My Billionaire Zoo
    ["1316383752fb549f8e75a93218eacbdd"] = true, -- My Dancing Animals
    ["5ab5fbf5370fcddf9c06972b1b8572ad"] = true, -- My Dealership
    ["eddb05390cf696d37dd656c2ddc5b9cb"] = true, -- My Dino Park
    ["7d98f14aa9420a7e89015cd3e2de35ba"] = true, -- My Farmers Garden
    ["776224566e1ded244fa9b98595deebc1"] = true, -- My Flower Shop
    ["3e98885cae0cae6afc2f5699a7d6a7ca"] = true, -- My Fruit Blender
    ["e17a0fb99b27aaecfa878399da3387b0"] = true, -- My Giant Farm
    ["f8bcbede7c2b585189de14cd535615b5"] = true, -- My Grass Farm
    ["7d34ffdfa0ff378c7e2005f0fd85636a"] = true, -- My Lucky Train
    ["aa27bc978fe06597866621952daf0561"] = true, -- My Moo Farm
    ["26b5e650f00dc4e4b429408bdf31cff6"] = true, -- My Pet Farm
    ["814563411077316e82d9b82facf4cb42"] = true, -- My Seafood Stand
    ["0073e6cd61fb14c214850e4a64b850e9"] = true, -- My Sword Empire
    ["a86ee8ccef201b8460e17b0e634ea3d5"] = true, -- My Timber Pets
    ["ed9a9641cfbaa177c5c69814ee409e48"] = true, -- My Toll Farm
    ["a1bf224d7bece31a09c8c157e6fd97ee"] = true, -- Oil Empire
    ["944334a119124aae0f9241d5ecb19337"] = true, -- Op Minh Kha Hup
    ["1fbb2880411b671d3426ac89450149e5"] = true, -- Open Sea for Animals
    ["a95868fb47e8a5af0053c362a1a5f0f9"] = true, -- Pan the River
    ["b7c85c870a0fc7fd337324b92b6a3f60"] = true, -- Parkour Pandemic
    ["8a1fd646337411610594baed8445e8c9"] = true, -- Penthouse Tycoon
    ["eb469970c6c999111608ab41e7c0e475"] = true, -- Pet Forest
    ["721d959af77ac0dc7c4c1062fc347176"] = true, -- Pets Universe
    ["ced5725469572347c58c96c9f18ca4db"] = true, -- Pickaxe Tycoon
    ["b403cc892357281a023b9bee4419a810"] = true, -- Pop Bubbles
    ["a238843629a8b61970d1110527f3f0bf"] = true, -- Popa Balloon RNG
    ["12a82041e366d8090c189e2a94206b51"] = true, -- Power Your City
    ["4f6bc95b2722a875784d93b5791bb798"] = true, -- Powera City
    ["4e5f21fc7c9f77291410ad55420fed6f"] = true, -- Pressa Keycap
    ["aabf02994b5438638148549f0621d6fe"] = true, -- Project Aura RNG
    ["fe658b6b44c08a7b2b337d4d07fb84ab"] = true, -- Prospecting
    ["bd5c22c7e2ac71d25206381ba26961c8"] = true, -- Pulla Lucky Fish
    ["4f40fbe6d451ac004b88fdec5f191e60"] = true, -- Race for Eggs
    ["b1314b52b13ada99facf9c7d32271e36"] = true, -- Race Horses
    ["bbc9aa74dc9c90d87c9731c943b6c6bd"] = true, -- Raceclick
    ["f9ca42dd3fc98cc8469db4b9a3dca30c"] = true, -- Raisean Anomaly
    ["b0c348633b8347989bc7a417ea7c72d5"] = true, -- RE Heads Please
    ["d188dc749967a339e690ea5546fb8aff"] = true, -- Rebirth Frenzy
    ["5fd2f11dd27167a45ee0e93fc3c87179"] = true, -- Redliner
    ["408a64519fa21ef58010eef0a9c062bd"] = true, -- REELED Shoot Fish
    ["aa5e6bd469eed6ea12ce0e5d8d3fae08"] = true, -- Rescue Animals
    ["da5e76bc8324284e9553a9d4479d5c9f"] = true, -- RN Gvs Fruit
    ["3f014fa58b2b70bfd0825fb9699b335b"] = true, -- Rocks RNG
    ["aaf820a660cfcfa8d20f8064f0b120b4"] = true, -- Roll a Basketball Team
    ["4f3c7d8c493aac1cf6acbd338d1c66da"] = true, -- Roll a Gnome
    ["bbe7b1ff1f6c6841c0a672ac66d3d5bd"] = true, -- Roll an Anime
    ["0c98a0b317f929978e77a0b10bc3e46c"] = true, -- Roll an Army
    ["bccabbcbd4e73b2f81f2c87776bce4eb"] = true, -- Roll Anime Fight
    ["8b439d73b2499dd5a7c7da5a417aad46"] = true, -- Roll Anime to Fight
    ["fd01b37acdc6c2c3ac048e4e56db09d6"] = true, -- Roll for Anime
    ["e723ac0b9b85db30ba23584c4506ef8e"] = true, -- Roll for Avatar Items
    ["01b834762e9157c94b92b9269e65d896"] = true, -- Roll for Chiikawa
    ["fc9894e7da5fd09e4ee3a7150c3635b9"] = true, -- Roll to Defend
    ["395cfd04815a1bc85c680dcfea008dab"] = true, -- Roll to Survive
    ["cc2fb0102d76adb3f835b6e54ef975c9"] = true, -- Roll Your Army
    ["9f8e33365d8876110f4e62ab4d7d6244"] = true, -- Rolla Fisherman
    ["272c49daa532fde4ef490bb33366e3ec"] = true, -- Rolla Sorcerer
    ["785423404682e060b88b7bc5ba44236a"] = true, -- Rolla Spirit
    ["7035e1a15af39207f4450e9e817bfc9b"] = true, -- Roller for Animals
    ["15dd5c741daaccdbcbdca3148a66df27"] = true, -- Runeheaven
    ["af0ecd7fb128f5cfcee8bcc312e71f04"] = true, -- Saber Simulator
    ["0ad974e96fcf1d5563ae963c28468a21"] = true, -- Sail for Eggs
    ["1a404677541c3df742b5481014a010db"] = true, -- Save Animals
    ["e023cf6aeb517ed72b51564db255a51f"] = true, -- Save Your Cat
    ["39478838419fd22b3d289fcc3f5e74e9"] = true, -- Scale Slimy Fish
    ["41751e077dd7aafb21dff34d9bd34cbc"] = true, -- Shufflean Egg
    ["b903b1bf7b2186a4437cf070527aa26d"] = true, -- Slap to Survive
    ["858bcd1fce4555d7e4c036fed136aa6c"] = true, -- Slime Card Collection
    ["d87d8a4ea8576135d228ee912e91c6b6"] = true, -- Snatcha Seed
    ["3632569537ade8f037fe41ed8461ce5e"] = true, -- Snowcone Stand
    ["683f23251115cc7e465006c7c1e39a53"] = true, -- Soccer Manager
    ["b1e8ba4d0be278492f336aa429cac560"] = true, -- Something Evil Will Happen
    ["bea543d14ab600dd4cfb9a1bbdfab5f2"] = true, -- Spina Car
    ["c34a7b54061b41749f8e9f1c0aaef896"] = true, -- Spina Fem
    ["81b968a7bb129af679ee1b1b79f1203a"] = true, -- Spina Superhero
    ["cfc5d23c84e39aaba9e6bed1434ff632"] = true, -- Star Catchers
    ["912cee64143d19f589b959332f7ac053"] = true, -- Steal a Lucky Egg
    ["cb7b2d9feab5822bcd4421ace5e1107f"] = true, -- Steal a Seed
    ["88b8e3f4db949d5fd92cbae8ab59233f"] = true, -- Steal a Seed for Bees
    ["07327bd73a0513b7b633900e187fc445"] = true, -- Steal a Tree
    ["b065f3282623ed1f9a860ed97606292e"] = true, -- Steal a VERITY
    ["b584626b5790654d365d906de3f9a69f"] = true, -- Steal an Anime Egg
    ["f427676b9d9f669e68a654d64fcdbc7c"] = true, -- Steal an Egg for Squishy Dumplings
    ["f5eb5eed703c1775689dc4ab67b09fab"] = true, -- Steal an Employee
    ["e5d6b14f5dd4598ef324d26c8a956b9f"] = true, -- Steal Brainrot Eggs
    ["37eec109b8badc1f3f38327c6e7ad67a"] = true, -- Steal Fish Eggs
    ["0329455354eef510af64def13bac7ac7"] = true, -- Steal From the Rich
    ["95fed101dc93d8760b7029c9b8740f50"] = true, -- Steal the Museum
    ["fd0331d71b55ac77c1556bee7cefcdf7"] = true, -- Steala Baby Egg
    ["de5c05bbcd1736ed460f54da47beae28"] = true, -- Steala Giant Egg
    ["e3fe950133c8524968daa2fbf29cf7de"] = true, -- Steala Mystery Egg
    ["4d7828ecd417c48407185d1a2fd29258"] = true, -- Stop the Bugs
    ["6d73b2a72a982b06adacccf3af3050b9"] = true, -- Stream a Cheese Pull
    ["1b4fbf298fcaa9772ce4f2ab90192372"] = true, -- Surf for Animals
    ["388e901972430102a6cd1389a117e7b2"] = true, -- Survive Anime Arena
    ["64c9da7b25f5b92b7c3dfe441d9b96da"] = true, -- Survive Lava for Animals
    ["683079406d949921e7424a64d18aad57"] = true, -- Survive the Swarm
    ["f5cc7ab65cd89692c841080c28f3f1d6"] = true, -- Survive Zombie Arena
    ["029343d28da771530d4d23dfa3098ff7"] = true, -- Swim for Eggs
    ["d2add62674094703bf5188d2f72d08ea"] = true, -- Swing for Eggs
    ["40cf168ce96d29aa1b72b02be561907f"] = true, -- Sword RNGX
    ["b18e95f75d27e57645b3b447cfab9442"] = true, -- Tap Buttons
    ["baf0493cf1620889644bc7c3c045df13"] = true, -- Tap4 Money
    ["5fa7861e2511d73d04f182b46dd72672"] = true, -- The Time Keeper (TTK)
    ["fa9f1fad144c43760905d9f253dbd6f8"] = true, -- The Veil
    ["9cd46cdebb0a107f5f5ad2639842599f"] = true, -- Throw an Anime Coin
    ["bcb3da36810df362f0fe092d96ad8ebd"] = true, -- Throwa Coin
    ["ba13aff659a4ba3704fa09d6d4a71f1a"] = true, -- Tossa Dice
    ["4a6bfab1b975d24e36238423e640f879"] = true, -- Tower VS Slimes
    ["ab0cbaf720d1f515089af4559b64ef83"] = true, -- Tree RNG
    ["f502a1c2071a36a78273eab76cd832d6"] = true, -- Tropical Resort Tycoon2
    ["bfacd9142de68c9daf5deaa98bf8fecc"] = true, -- Ultimate Tower Defense
    ["3f61f3cf1f848061e91f772a0fc04fdb"] = true, -- Unbox ASMR
    ["4533c88fcdbf86c871cbf767a43901ae"] = true, -- Unfreeze an Animal
    ["c8c1177a8986b698c87e896c1c3d99e4"] = true, -- Untitled Melee RNG
    ["f7f6677de1931d45cd3706d5597cf16c"] = true, -- Where Seasons Pass
    ["aa2e316ed2fa0adafb042e08a1edba26"] = true, -- Your Lumber Farm
    ["a966134c8ca36caeeff5f92691cc707c"] = true, -- Zombies
    ["4609f6d37567c4cd431511de739f27a1"] = true, -- Zone Defense RNG
}

for _, def in ipairs(GAMES) do
    if PLACEHOLDER_IDS[def.id] then
        continue
    end
    local entry = { name = def.name, id = def.id, url = def.url or LOADER_URL:format(def.id) }
    for _, id in ipairs(def.places) do
        registerLoader(LOADERS_BY_PLACE, "PlaceId", id, entry)
    end
    for _, id in ipairs(def.universes) do
        registerLoader(LOADERS_BY_GAME, "GameId", id, entry)
    end
end

local DISCORD_URL = "https://discord.gg/getsnowy"
local PRICING_URL = "https://getsnowy.xyz/pricing"

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

local COLORS = {
    backdrop = Color3.fromRGB(2, 6, 12),
    shell = Color3.fromRGB(6, 11, 20),
    glass = Color3.fromRGB(13, 23, 39),
    glassDeep = Color3.fromRGB(8, 16, 29),
    glassRaised = Color3.fromRGB(20, 33, 54),
    userPanel = Color3.fromRGB(7, 25, 34),
    surface = Color3.fromRGB(16, 27, 45),
    surfaceRaised = Color3.fromRGB(23, 36, 59),
    surfaceHover = Color3.fromRGB(31, 48, 75),
    surfacePressed = Color3.fromRGB(14, 24, 42),
    input = Color3.fromRGB(7, 15, 28),
    inputFocus = Color3.fromRGB(11, 24, 41),
    divider = Color3.fromRGB(87, 119, 154),
    primary = Color3.fromRGB(26, 164, 235),
    primaryHover = Color3.fromRGB(49, 183, 246),
    primaryPressed = Color3.fromRGB(17, 132, 199),
    secondary = Color3.fromRGB(27, 45, 72),
    secondaryHover = Color3.fromRGB(38, 61, 95),
    secondaryPressed = Color3.fromRGB(19, 34, 57),
    text = Color3.fromRGB(239, 245, 255),
    textMuted = Color3.fromRGB(162, 181, 209),
    textFaint = Color3.fromRGB(108, 132, 163),
    cyan = Color3.fromRGB(67, 207, 255),
    success = Color3.fromRGB(47, 224, 151),
    warning = Color3.fromRGB(255, 190, 91),
    danger = Color3.fromRGB(255, 97, 120),
    premium = Color3.fromRGB(246, 192, 79),
    premiumSurface = Color3.fromRGB(25, 22, 36),
    premiumAction = Color3.fromRGB(126, 87, 232),
    premiumHover = Color3.fromRGB(150, 111, 247),
    premiumPressed = Color3.fromRGB(99, 67, 193),
    disabled = Color3.fromRGB(35, 45, 62),
}

local MOTION = {
    quick = 0.12,
    normal = 0.22,
    slow = 0.34,
}

local LUCIDE = {
    user = {
        image = "rbxassetid://16898613869",
        size = Vector2.new(48, 48),
        offset = Vector2.new(661, 869),
    },
    settings = {
        image = "rbxassetid://16898613777",
        size = Vector2.new(48, 48),
        offset = Vector2.new(771, 257),
    },
    shield = {
        image = "rbxassetid://16898613777",
        size = Vector2.new(48, 48),
        offset = Vector2.new(869, 0),
    },
    globe = {
        image = "rbxassetid://16898613509",
        size = Vector2.new(48, 48),
        offset = Vector2.new(771, 563),
    },
    save = {
        image = "rbxassetid://16898613699",
        size = Vector2.new(48, 48),
        offset = Vector2.new(918, 453),
    },
    minus = { image = "rbxassetid://7734000129" },
    x = { image = "rbxassetid://7743878857" },
    key = { image = "rbxassetid://7733965118" },
    ["shield-check"] = { image = "rbxassetid://7734056411" },
    ["message-circle"] = { image = "rbxassetid://7733993311" },
    copy = { image = "rbxassetid://7733764083" },
    monitor = { image = "rbxassetid://7734002839" },
    smartphone = { image = "rbxassetid://7734058979" },
    gamepad = { image = "rbxassetid://7733799901" },
    clock = { image = "rbxassetid://7733734848" },
    wifi = { image = "rbxassetid://7743878148" },
    ["external-link"] = { image = "rbxassetid://7743866903" },
    ["alert-circle"] = { image = "rbxassetid://7733658271" },
    ["check-circle"] = { image = "rbxassetid://7733919427" },
    info = { image = "rbxassetid://7733964719" },
    server = { image = "rbxassetid://7734053426" },
}

local DESKTOP_WIDTH = 930
local COMPACT_WIDTH = 644
local SHELL_HEIGHT = 620
local SNOW_TEXTURE = "rbxthumb://type=Asset&id=68072539&w=150&h=150"
local DESKTOP_SNOWFLAKES = 18
local COMPACT_SNOWFLAKES = 10
local activeTweens = setmetatable({}, { __mode = "k" })

local function loaderCandidates()
    local placeId = tonumber(game.PlaceId) or 0
    local gameId = tonumber(game.GameId) or 0
    return LOADERS_BY_PLACE[placeId] or LOADERS_BY_GAME[gameId] or {}
end

-- default is the last row registered for this game (what older loaders picked); players can switch
local candidates = loaderCandidates()
local candidateIndex = #candidates
local PICK_FILE = ("SnowyHub_Pick_%d.txt"):format(tonumber(game.GameId) or 0)

local function resolveLoader()
    return candidates[candidateIndex] or UNIVERSAL_LOADER
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeKey(value)
    local key = trim(tostring(value or ""))
    local first = key:sub(1, 1)
    local last = key:sub(-1)
    if #key >= 2 and ((first == "\"" and last == "\"") or (first == "'" and last == "'")) then
        key = trim(key:sub(2, -2))
    end
    return key
end

local function copyText(value)
    local copier = setclipboard or toclipboard
    if type(copier) ~= "function" then
        return false
    end
    return (pcall(copier, tostring(value)))
end

local function executorName()
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name then return tostring(name) end
    end
    return "Unknown"
end

local function deviceName()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    end
    return "PC"
end

local function readableHwid()
    -- built with inserts: a `{ gethwid, get_hwid }` literal leaves a nil hole that stops ipairs early
    local providers = {}
    if type(gethwid) == "function" then table.insert(providers, gethwid) end
    if type(get_hwid) == "function" then table.insert(providers, get_hwid) end
    if type(syn) == "table" and type(syn.gethwid) == "function" then
        table.insert(providers, syn.gethwid)
    end
    for _, provider in ipairs(providers) do
        local ok, value = pcall(provider)
        if ok and value and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    return nil
end

local parent = CoreGui
pcall(function()
    if type(gethui) == "function" then parent = gethui() end
end)

pcall(function()
    local previous = parent:FindFirstChild("SnowyFlowAuthLoader")
    if previous then previous:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "SnowyFlowAuthLoader"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

-- every connection to a service/camera signal goes through track() so nothing outlives the gui
local connections = {}
local function track(connection)
    table.insert(connections, connection)
    return connection
end
gui.Destroying:Connect(function()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end)

local clickSound = Instance.new("Sound")
clickSound.Name = "SnowyClick"
clickSound.SoundId = "rbxassetid://6895079853"
clickSound.Volume = 0.42
clickSound.PlaybackSpeed = 1
clickSound.Looped = false
clickSound.Parent = gui

local function playClickSound()
    pcall(function()
        clickSound.TimePosition = 0
        clickSound:Play()
    end)
end

local function create(className, properties, targetParent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = targetParent
    return object
end

local function round(object, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end

local function glassSurface(object, topColor, bottomColor, transparency, radius)
    object.BackgroundColor3 = topColor or COLORS.glass
    object.BackgroundTransparency = transparency or 0.3
    object.BorderSizePixel = 0
    object.ClipsDescendants = true
    round(object, radius or 14)
    create("UIGradient", {
        Color = ColorSequence.new(
            topColor or COLORS.glassRaised,
            bottomColor or COLORS.glassDeep
        ),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.02),
            NumberSequenceKeypoint.new(1, 0.10),
        }),
        Rotation = 105,
    }, object)
    return object
end

local function applyLucideData(icon, iconName)
    local data = LUCIDE[iconName] or LUCIDE.info
    icon.Image = data.image
    if data.offset and data.size then
        icon.ImageRectOffset = data.offset
        icon.ImageRectSize = data.size
    else
        icon.ImageRectOffset = Vector2.new(0, 0)
        icon.ImageRectSize = Vector2.new(0, 0)
    end
end

local function lucideIcon(parentObject, iconName, position, size, color, zIndex)
    local icon = create("ImageLabel", {
        Name = "LucideIcon",
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        ImageColor3 = color or COLORS.textMuted,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zIndex or 4,
    }, parentObject)
    applyLucideData(icon, iconName)
    return icon
end

local function playTween(object, duration, properties, easingStyle, easingDirection, channel)
    local bucket = activeTweens[object]
    if not bucket then
        bucket = {}
        activeTweens[object] = bucket
    end
    local key = channel or "default"
    local previous = bucket[key]
    if previous then
        previous:Cancel()
    end
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            easingStyle or Enum.EasingStyle.Quint,
            easingDirection or Enum.EasingDirection.Out
        ),
        properties
    )
    bucket[key] = tween
    tween.Completed:Connect(function()
        if bucket[key] == tween then
            bucket[key] = nil
        end
    end)
    tween:Play()
    return tween
end

local function textLabel(parentObject, text, position, size, font, textSize, color, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = font or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or COLORS.text,
        TextSize = textSize or 13,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parentObject)
end

local function bindButtonMotion(button, baseColor, hoverColor, pressedColor)
    local scale = button:FindFirstChildOfClass("UIScale")
    local function animate(color, value)
        if button:GetAttribute("MotionDisabled") then return end
        playTween(button, MOTION.quick, { BackgroundColor3 = color })
        if scale then
            playTween(scale, MOTION.quick, { Scale = value })
        end
    end

    button.MouseEnter:Connect(function()
        animate(hoverColor, 1.015)
    end)
    button.MouseLeave:Connect(function()
        animate(baseColor, 1)
    end)
    button.MouseButton1Down:Connect(function()
        animate(pressedColor, 0.975)
    end)
    button.MouseButton1Up:Connect(function()
        animate(hoverColor, 1.01)
    end)
end

local function makeButton(parentObject, name, text, position, size, baseColor, hoverColor, pressedColor, iconName)
    local button = create("TextButton", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = baseColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        Text = "",
        TextColor3 = COLORS.text,
    }, parentObject)
    round(button, 11)
    create("UIScale", { Scale = 1 }, button)
    local content = create("Frame", {
        Name = "ButtonContent",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        ZIndex = 5,
    }, button)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, iconName and 8 or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)
    if iconName then
        local icon = lucideIcon(
            content,
            iconName,
            UDim2.new(),
            UDim2.fromOffset(16, 16),
            COLORS.text,
            5
        )
        icon.LayoutOrder = 1
        icon.ImageTransparency = 0.08
    end
    local label = textLabel(
        content,
        text,
        UDim2.new(),
        UDim2.fromOffset(0, 18),
        Enum.Font.GothamBold,
        13,
        COLORS.text,
        Enum.TextXAlignment.Center
    )
    label.Name = "ButtonLabel"
    label.AutomaticSize = Enum.AutomaticSize.X
    label.LayoutOrder = 2
    label.TextTruncate = Enum.TextTruncate.None
    label.ZIndex = 5
    bindButtonMotion(
        button,
        baseColor,
        hoverColor or COLORS.surfaceHover,
        pressedColor or COLORS.surfacePressed
    )
    button.Activated:Connect(function()
        if button.Active and not button:GetAttribute("MotionDisabled") then
            playClickSound()
        end
    end)
    return button
end

local function setButtonText(button, value)
    local label = button:FindFirstChild("ButtonLabel", true)
    if label then
        label.Text = tostring(value or "")
    end
end

local function setButtonTextSize(button, value)
    local label = button:FindFirstChild("ButtonLabel", true)
    if label then
        label.TextSize = value
    end
end

local function makeIconButton(parentObject, name, iconName, position, baseColor, hoverColor, pressedColor)
    local button = create("ImageButton", {
        Name = name,
        Position = position,
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = baseColor,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        Image = "",
    }, parentObject)
    round(button, 10)
    create("UIScale", { Scale = 1 }, button)
    lucideIcon(button, iconName, UDim2.fromOffset(8, 8), UDim2.fromOffset(16, 16), COLORS.textMuted, 5)
    bindButtonMotion(button, baseColor, hoverColor, pressedColor)
    button.Activated:Connect(function()
        if button.Active and not button:GetAttribute("MotionDisabled") then
            playClickSound()
        end
    end)
    return button
end

local function setButtonEnabled(button, enabled)
    button.Active = enabled
    button:SetAttribute("MotionDisabled", not enabled)
    playTween(button, MOTION.quick, {
        BackgroundColor3 = enabled and COLORS.secondary or COLORS.disabled,
    })
    local label = button:FindFirstChild("ButtonLabel", true)
    if label then
        playTween(label, MOTION.quick, { TextTransparency = enabled and 0 or 0.28 })
    end
    local icon = button:FindFirstChild("LucideIcon", true)
    if icon then
        playTween(icon, MOTION.quick, { ImageTransparency = enabled and 0.08 or 0.45 })
    end
end

local backdrop = create("Frame", {
    Name = "Backdrop",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = COLORS.backdrop,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, gui)
create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 15, 25)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(5, 9, 17)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 8, 22)),
    }),
    Rotation = 18,
}, backdrop)

local shell = create("CanvasGroup", {
    Name = "Shell",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(DESKTOP_WIDTH, SHELL_HEIGHT),
    BackgroundTransparency = 1,
    GroupTransparency = 1,
}, backdrop)
local shellScale = create("UIScale", { Scale = 0.96 }, shell)

local shellChrome = create("Frame", {
    Name = "Chrome",
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    ZIndex = 2,
}, shell)
glassSurface(shellChrome, Color3.fromRGB(12, 23, 39), COLORS.shell, 0.12, 22)

local snowLayer = create("Frame", {
    Name = "SnowLayer",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = false,
    ZIndex = 2,
}, shellChrome)
local snowRandom = Random.new()
local snowflakes = {}
local snowTweens = {}

local function runSnowflake(carrier, flake, index)
    task.delay((index - 1) * 0.55, function()
        while gui.Parent and carrier.Parent do
            local shellWidth = math.max(180, shell.Size.X.Offset)
            local depthBand = (index - 1) % 3
            local minimumSize = depthBand == 0 and 6 or (depthBand == 1 and 9 or 12)
            local maximumSize = depthBand == 0 and 10 or (depthBand == 1 and 14 or 18)
            local minimumTransparency = depthBand == 0 and 0.68 or (depthBand == 1 and 0.54 or 0.46)
            local maximumTransparency = depthBand == 0 and 0.82 or (depthBand == 1 and 0.70 or 0.62)
            local size = snowRandom:NextInteger(minimumSize, maximumSize)
            local startX = snowRandom:NextInteger(10, math.max(10, shellWidth - size - 10))
            local drift = snowRandom:NextInteger(-34, 34)
            local duration = snowRandom:NextNumber(7.5, 12.5)

            carrier.Position = UDim2.fromOffset(startX, -size - 10)
            flake.Position = UDim2.fromOffset(0, 0)
            flake.Size = UDim2.fromOffset(size, size)
            flake.ImageTransparency = snowRandom:NextNumber(minimumTransparency, maximumTransparency)
            flake.Rotation = snowRandom:NextInteger(-35, 35)

            local fallTween = TweenService:Create(
                carrier,
                TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                { Position = UDim2.fromOffset(startX, SHELL_HEIGHT + size + 12) }
            )
            local driftTween = TweenService:Create(
                flake,
                TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {
                    Position = UDim2.fromOffset(drift, 0),
                    Rotation = flake.Rotation + snowRandom:NextInteger(-90, 90),
                }
            )
            snowTweens[carrier] = { fallTween, driftTween }
            fallTween:Play()
            driftTween:Play()
            fallTween.Completed:Wait()
            driftTween:Cancel()
            snowTweens[carrier] = nil
            task.wait(snowRandom:NextNumber(0.2, 1.2))
        end
    end)
end

for index = 1, DESKTOP_SNOWFLAKES do
    local carrier = create("Frame", {
        Name = "SnowCarrier" .. tostring(index),
        Size = UDim2.fromOffset(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 2,
    }, snowLayer)
    local flake = create("ImageLabel", {
        Name = "Snowflake" .. tostring(index),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = SNOW_TEXTURE,
        ScaleType = Enum.ScaleType.Fit,
        Active = false,
        ZIndex = 2,
    }, carrier)
    snowflakes[index] = carrier
    runSnowflake(carrier, flake, index)
end

local function setSnowflakeCount(count)
    for index, carrier in ipairs(snowflakes) do
        carrier.Visible = index <= count
    end
end

gui.Destroying:Connect(function()
    for _, tweens in pairs(snowTweens) do
        for _, tween in ipairs(tweens) do
            tween:Cancel()
        end
    end
end)

local userPanel = create("Frame", {
    Name = "UserInfo",
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.fromOffset(278, 604),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
}, shellChrome)

local mainPanel = create("Frame", {
    Name = "Main",
    Position = UDim2.fromOffset(294, 8),
    Size = UDim2.fromOffset(628, 604),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 3,
}, shellChrome)

local columnDivider = create("Frame", {
    Name = "ColumnDivider",
    Position = UDim2.fromOffset(286, 20),
    Size = UDim2.new(0, 1, 1, -40),
    BackgroundColor3 = COLORS.divider,
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
    ZIndex = 3,
}, shellChrome)

lucideIcon(userPanel, "user", UDim2.fromOffset(20, 19), UDim2.fromOffset(15, 15), COLORS.cyan, 5)
textLabel(userPanel, "User Info", UDim2.fromOffset(43, 14), UDim2.new(1, -62, 0, 26), Enum.Font.GothamBold, 11, COLORS.cyan)
create("Frame", {
    Position = UDim2.fromOffset(18, 48),
    Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = COLORS.divider,
    BackgroundTransparency = 0.72,
    BorderSizePixel = 0,
}, userPanel)

local avatarHalo = create("Frame", {
    Name = "AvatarHalo",
    Position = UDim2.new(0.5, -50, 0, 58),
    Size = UDim2.fromOffset(100, 100),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, userPanel)
round(avatarHalo, 50)
local avatarRing = create("Frame", {
    Name = "AvatarGradientRing",
    Position = UDim2.fromOffset(4, 4),
    Size = UDim2.fromOffset(92, 92),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, avatarHalo)
round(avatarRing, 46)
local avatarRingStroke = create("UIStroke", {
    Name = "AvatarRingStroke",
    Color = COLORS.cyan,
    Thickness = 3,
    Transparency = 0,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, avatarRing)
create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 224, 255)),
        ColorSequenceKeypoint.new(0.52, COLORS.primary),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 102, 255)),
    }),
    Rotation = 35,
}, avatarRingStroke)
local avatarSeparator = create("Frame", {
    Name = "AvatarSeparator",
    Position = UDim2.fromOffset(2, 2),
    Size = UDim2.fromOffset(88, 88),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, avatarRing)
round(avatarSeparator, 44)
local avatar = create("ImageLabel", {
    Position = UDim2.fromOffset(2, 2),
    Size = UDim2.fromOffset(84, 84),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Image = "rbxassetid://0",
    ScaleType = Enum.ScaleType.Crop,
}, avatarSeparator)
round(avatar, 42)
local onlineDot = create("Frame", {
    Name = "OnlineDotBacking",
    Position = UDim2.new(1, -26, 1, -26),
    Size = UDim2.fromOffset(22, 22),
    BackgroundColor3 = Color3.fromRGB(4, 12, 23),
    BorderSizePixel = 0,
}, avatarHalo)
round(onlineDot, 11)
local onlineCore = create("Frame", {
    Position = UDim2.fromOffset(5, 5),
    Size = UDim2.fromOffset(12, 12),
    BackgroundColor3 = COLORS.success,
    BorderSizePixel = 0,
}, onlineDot)
round(onlineCore, 6)
local onlinePulseUp = TweenService:Create(
    onlineCore,
    TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { BackgroundColor3 = Color3.fromRGB(90, 255, 186) }
)
onlinePulseUp:Play()
gui.Destroying:Connect(function()
    onlinePulseUp:Cancel()
end)
-- thumbnail fetch yields; don't block building the rest of the UI on it
task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    if ok and image and avatar.Parent then
        avatar.Image = image
    end
end)

local displayName = player and (player.DisplayName or player.Name) or "Snowy User"
local userName = player and player.Name or "unknown"
textLabel(userPanel, displayName, UDim2.fromOffset(18, 164), UDim2.new(1, -36, 0, 22), Enum.Font.GothamBold, 14, COLORS.text, Enum.TextXAlignment.Center)
textLabel(userPanel, "@" .. userName, UDim2.fromOffset(18, 185), UDim2.new(1, -36, 0, 18), Enum.Font.Gotham, 10, COLORS.textFaint, Enum.TextXAlignment.Center)

-- restore the script this player picked last time for this game
pcall(function()
    if #candidates > 1 and type(isfile) == "function" and type(readfile) == "function" and isfile(PICK_FILE) then
        local saved = trim(readfile(PICK_FILE))
        for index, entry in ipairs(candidates) do
            if entry.id == saved then
                candidateIndex = index
                break
            end
        end
    end
end)

local function gameLabel()
    local entry = resolveLoader()
    if #candidates > 1 then
        return ("%s (%d/%d)"):format(entry.name, candidateIndex, #candidates)
    end
    return entry.name
end

local selected = resolveLoader()
local gameTone = selected.universal and COLORS.warning or COLORS.success
local infoGroup = create("Frame", {
    Name = "ProfileDetails",
    Position = UDim2.fromOffset(18, 214),
    Size = UDim2.new(1, -36, 0, 166),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, userPanel)
local device = deviceName()
local stats = {
    { "Executor", executorName(), "monitor", COLORS.textMuted },
    { "Device", device, device == "Mobile" and "smartphone" or "monitor", COLORS.textMuted },
    { "HWID", readableHwid() and "Available" or "FlowAuth managed", "shield", COLORS.textMuted },
    { "Game", gameLabel(), "gamepad", gameTone },
}
local gameValueLabel
for index, item in ipairs(stats) do
    local y = (index - 1) * 41
    lucideIcon(infoGroup, item[3], UDim2.fromOffset(14, y + 12), UDim2.fromOffset(16, 16), item[4], 5)
    textLabel(infoGroup, item[1], UDim2.fromOffset(42, y + 4), UDim2.fromOffset(78, 15), Enum.Font.GothamMedium, 9, COLORS.textFaint)
    local valueLabel = textLabel(infoGroup, item[2], UDim2.fromOffset(42, y + 18), UDim2.new(1, -56, 0, 18), Enum.Font.GothamMedium, 10, item[4])
    if item[1] == "Game" then
        gameValueLabel = valueLabel
    end
    if index < #stats then
        create("Frame", {
            Position = UDim2.fromOffset(42, y + 40),
            Size = UDim2.new(1, -56, 0, 1),
            BackgroundColor3 = COLORS.divider,
            BackgroundTransparency = 0.84,
            BorderSizePixel = 0,
        }, infoGroup)
    end
end

local metricsStrip = create("Frame", {
    Name = "Metrics",
    Position = UDim2.fromOffset(18, 392),
    Size = UDim2.new(1, -36, 0, 66),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, userPanel)
create("Frame", {
    Position = UDim2.new(0.5, 0, 0, 12),
    Size = UDim2.new(0, 1, 1, -24),
    BackgroundColor3 = COLORS.divider,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
}, metricsStrip)

local sessionCard = create("Frame", {
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
}, metricsStrip)
lucideIcon(sessionCard, "clock", UDim2.fromOffset(14, 16), UDim2.fromOffset(16, 16), COLORS.cyan, 5)
textLabel(sessionCard, "Session", UDim2.fromOffset(38, 9), UDim2.new(1, -48, 0, 18), Enum.Font.GothamMedium, 9, COLORS.textFaint)
local sessionText = textLabel(sessionCard, "00:00", UDim2.fromOffset(38, 27), UDim2.new(1, -48, 0, 22), Enum.Font.GothamBold, 12, COLORS.cyan)

local pingCard = create("Frame", {
    Position = UDim2.fromScale(0.5, 0),
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
}, metricsStrip)
lucideIcon(pingCard, "wifi", UDim2.fromOffset(14, 16), UDim2.fromOffset(16, 16), COLORS.success, 5)
textLabel(pingCard, "Ping", UDim2.fromOffset(38, 9), UDim2.new(1, -48, 0, 18), Enum.Font.GothamMedium, 9, COLORS.textFaint)
local pingText = textLabel(pingCard, "-- ms", UDim2.fromOffset(38, 27), UDim2.new(1, -48, 0, 22), Enum.Font.GothamBold, 12, COLORS.success)

local connectionCard = create("Frame", {
    Position = UDim2.fromOffset(18, 502),
    Size = UDim2.new(1, -36, 0, 68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, userPanel)
lucideIcon(connectionCard, "check-circle", UDim2.fromOffset(14, 24), UDim2.fromOffset(20, 20), COLORS.success, 5)
textLabel(connectionCard, "Connected to Snowy Hub", UDim2.fromOffset(44, 11), UDim2.new(1, -56, 0, 24), Enum.Font.GothamBold, 12, COLORS.success)
textLabel(connectionCard, "Snowy Hub is ready", UDim2.fromOffset(44, 35), UDim2.new(1, -56, 0, 18), Enum.Font.Gotham, 9, COLORS.textMuted)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundTransparency = 1,
    Active = true,
}, mainPanel)
textLabel(header, "Snowy Hub", UDim2.fromOffset(22, 8), UDim2.fromOffset(160, 30), Enum.Font.GothamBold, 22, COLORS.text)
textLabel(header, "Secure FlowAuth loader", UDim2.fromOffset(23, 35), UDim2.fromOffset(190, 16), Enum.Font.Gotham, 9, COLORS.textFaint)

local minimize = makeIconButton(
    header,
    "Minimize",
    "minus",
    UDim2.new(1, -82, 0, 14),
    COLORS.surfaceRaised,
    COLORS.surfaceHover,
    COLORS.surfacePressed
)
local close = makeIconButton(
    header,
    "Close",
    "x",
    UDim2.new(1, -44, 0, 14),
    COLORS.surfaceRaised,
    Color3.fromRGB(74, 38, 53),
    Color3.fromRGB(54, 27, 40)
)
create("Frame", {
    Position = UDim2.fromOffset(20, 61),
    Size = UDim2.new(1, -40, 0, 1),
    BackgroundColor3 = COLORS.divider,
    BackgroundTransparency = 0.74,
    BorderSizePixel = 0,
}, header)

local serviceCard = create("Frame", {
    Name = "ServiceCard",
    Position = UDim2.fromOffset(20, 74),
    Size = UDim2.new(1, -40, 0, 88),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, mainPanel)
local serviceLogoSlot = create("Frame", {
    Name = "ServiceLogoSlot",
    Position = UDim2.fromOffset(0, 2),
    Size = UDim2.fromOffset(116, 82),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, serviceCard)
create("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(132, 88),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Image = "rbxassetid://123802801726537",
    ScaleType = Enum.ScaleType.Fit,
}, serviceLogoSlot)
textLabel(serviceCard, "ACTIVE SERVICE", UDim2.fromOffset(128, 11), UDim2.new(1, -318, 0, 17), Enum.Font.GothamBold, 9, COLORS.success)
textLabel(serviceCard, "Snowy Studios", UDim2.fromOffset(128, 29), UDim2.new(1, -318, 0, 24), Enum.Font.GothamBold, 15, COLORS.text)
textLabel(serviceCard, "Verified client delivery", UDim2.fromOffset(128, 54), UDim2.new(1, -318, 0, 18), Enum.Font.Gotham, 10, COLORS.textFaint)
local secureBadge = create("Frame", {
    Position = UDim2.new(1, -172, 0.5, -17),
    Size = UDim2.fromOffset(154, 34),
    BackgroundColor3 = Color3.fromRGB(10, 53, 44),
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
}, serviceCard)
round(secureBadge, 9)
lucideIcon(secureBadge, "shield-check", UDim2.fromOffset(12, 9), UDim2.fromOffset(16, 16), COLORS.success, 5)
textLabel(secureBadge, "FLOWAUTH VERIFIED", UDim2.fromOffset(36, 0), UDim2.new(1, -44, 1, 0), Enum.Font.GothamBold, 9, COLORS.success)

textLabel(mainPanel, "SECURE ACCESS", UDim2.fromOffset(22, 174), UDim2.new(1, -44, 0, 16), Enum.Font.GothamBold, 9, COLORS.cyan)
textLabel(mainPanel, "Enter your FlowAuth key to launch the supported script", UDim2.fromOffset(22, 190), UDim2.new(1, -44, 0, 19), Enum.Font.Gotham, 11, COLORS.textMuted)

local input = create("TextBox", {
    Name = "KeyInput",
    Position = UDim2.fromOffset(20, 214),
    Size = UDim2.new(1, -40, 0, 50),
    BackgroundColor3 = COLORS.input,
    BackgroundTransparency = 0.24,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.GothamMedium,
    PlaceholderText = "Paste your FlowAuth key",
    PlaceholderColor3 = COLORS.textMuted,
    Text = "",
    TextColor3 = COLORS.text,
    TextTransparency = 0,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, mainPanel)
round(input, 12)
local inputFocused = false
local inputBorder = create("UIStroke", {
    Name = "KeyInputBorder",
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = COLORS.cyan,
    Thickness = 1.35,
    Transparency = 0.18,
}, input)
local inputBorderGradient = create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 64, 143)),
        ColorSequenceKeypoint.new(0.44, Color3.fromRGB(37, 133, 222)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(99, 232, 255)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(37, 133, 222)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 64, 143)),
    }),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.58),
        NumberSequenceKeypoint.new(0.40, 0.38),
        NumberSequenceKeypoint.new(0.50, 0),
        NumberSequenceKeypoint.new(0.62, 0.38),
        NumberSequenceKeypoint.new(1, 0.58),
    }),
    Rotation = 0,
}, inputBorder)
local inputBorderSpin = TweenService:Create(
    inputBorderGradient,
    TweenInfo.new(2.65, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
    { Rotation = 360 }
)
inputBorderSpin:Play()
gui.Destroying:Connect(function()
    inputBorderSpin:Cancel()
end)
local inputKeyIcon = lucideIcon(mainPanel, "key", UDim2.fromOffset(36, 230), UDim2.fromOffset(18, 18), COLORS.textMuted, 5)
create("UIPadding", {
    PaddingLeft = UDim.new(0, 46),
    PaddingRight = UDim.new(0, 16),
}, input)

local primaryRow = create("Frame", {
    Position = UDim2.fromOffset(20, 276),
    Size = UDim2.new(1, -40, 0, 46),
    BackgroundTransparency = 1,
}, mainPanel)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, primaryRow)
local getKey = makeButton(primaryRow, "GetKey", "Get Key", UDim2.new(), UDim2.new(0.5, -5, 1, 0), COLORS.primary, COLORS.primaryHover, COLORS.primaryPressed, "key")
getKey.LayoutOrder = 1
local redeem = makeButton(primaryRow, "Redeem", "Redeem", UDim2.new(), UDim2.new(0.5, -5, 1, 0), COLORS.secondary, COLORS.secondaryHover, COLORS.secondaryPressed, "shield-check")
redeem.LayoutOrder = 2

local utilityRow = create("Frame", {
    Position = UDim2.fromOffset(20, 334),
    Size = UDim2.new(1, -40, 0, 38),
    BackgroundTransparency = 1,
}, mainPanel)
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, utilityRow)
local discord = makeButton(utilityRow, "Discord", "Discord", UDim2.new(), UDim2.new(1 / 3, -6, 1, 0), COLORS.surfaceRaised, COLORS.surfaceHover, COLORS.surfacePressed, "message-circle")
discord.LayoutOrder = 1
local copyHwid = makeButton(utilityRow, "CopyHWID", "Copy HWID", UDim2.new(), UDim2.new(1 / 3, -6, 1, 0), COLORS.surfaceRaised, COLORS.surfaceHover, COLORS.surfacePressed, "copy")
copyHwid.LayoutOrder = 2
local settingsButton = makeButton(utilityRow, "Settings", "Settings", UDim2.new(), UDim2.new(1 / 3, -6, 1, 0), COLORS.surfaceRaised, COLORS.surfaceHover, COLORS.surfacePressed, "settings")
settingsButton.LayoutOrder = 3
setButtonTextSize(discord, 11)
setButtonTextSize(copyHwid, 11)
setButtonTextSize(settingsButton, 11)

local statusCard = create("Frame", {
    Name = "StatusCard",
    Position = UDim2.fromOffset(20, 384),
    Size = UDim2.new(1, -40, 0, 46),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, mainPanel)
local statusAccent = create("Frame", {
    Position = UDim2.fromOffset(0, 8),
    Size = UDim2.new(0, 3, 1, -16),
    BackgroundColor3 = COLORS.cyan,
    BorderSizePixel = 0,
}, statusCard)
round(statusAccent, 2)
local statusIcon = lucideIcon(statusCard, "info", UDim2.fromOffset(16, 15), UDim2.fromOffset(16, 16), COLORS.cyan, 5)
local statusSummary = textLabel(statusCard, "", UDim2.fromOffset(42, 13), UDim2.new(1, -58, 0, 20), Enum.Font.GothamBold, 11, COLORS.textMuted)
statusSummary.Name = "StatusSummary"
local statusDetail = textLabel(statusCard, "", UDim2.fromOffset(42, 34), UDim2.new(1, -58, 0, 38), Enum.Font.Gotham, 9, COLORS.textMuted)
statusDetail.Name = "StatusDetail"
statusDetail.TextWrapped = true
statusDetail.TextTruncate = Enum.TextTruncate.None
statusDetail.TextYAlignment = Enum.TextYAlignment.Top
statusDetail.Visible = false
local copyError = makeButton(statusCard, "CopyError", "Copy Error", UDim2.new(1, -108, 0, 8), UDim2.fromOffset(94, 26), COLORS.surfaceRaised, COLORS.surfaceHover, COLORS.surfacePressed, "copy")
setButtonTextSize(copyError, 9)
copyError.Visible = false
local switchScript = makeButton(statusCard, "SwitchScript", "Switch script", UDim2.new(1, -108, 0, 8), UDim2.fromOffset(94, 26), COLORS.surfaceRaised, COLORS.surfaceHover, COLORS.surfacePressed, "gamepad")
setButtonTextSize(switchScript, 9)
switchScript.Visible = #candidates > 1

local accessCard = create("Frame", {
    Name = "PremiumAccess",
    Position = UDim2.fromOffset(20, 442),
    Size = UDim2.new(1, -40, 0, 146),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, mainPanel)
create("Frame", {
    Name = "PremiumDivider",
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = COLORS.divider,
    BackgroundTransparency = 0.84,
    BorderSizePixel = 0,
}, accessCard)
local premiumBadge = textLabel(accessCard, "SNOWY+", UDim2.fromOffset(18, 14), UDim2.fromOffset(62, 18), Enum.Font.GothamBold, 8, COLORS.premium, Enum.TextXAlignment.Center)
premiumBadge.BackgroundTransparency = 0
premiumBadge.BackgroundColor3 = Color3.fromRGB(67, 50, 27)
round(premiumBadge, 6)
textLabel(accessCard, "Premium Access", UDim2.fromOffset(18, 40), UDim2.new(1, -170, 0, 22), Enum.Font.GothamBold, 15, COLORS.text)
textLabel(accessCard, "Unlock extra perks and priority support", UDim2.fromOffset(18, 64), UDim2.new(1, -170, 0, 19), Enum.Font.GothamMedium, 11, COLORS.textMuted)
textLabel(accessCard, "getsnowy.xyz/pricing", UDim2.fromOffset(18, 87), UDim2.new(1, -170, 0, 18), Enum.Font.GothamMedium, 10, COLORS.premium)
local premiumPerks = textLabel(accessCard, "Priority support  |  Extra tools  |  Early access", UDim2.fromOffset(18, 111), UDim2.new(1, -170, 0, 19), Enum.Font.GothamMedium, 10, COLORS.textFaint)
local plansSlot = create("Frame", {
    Name = "PlansSlot",
    Position = UDim2.new(1, -136, 0.5, -20),
    Size = UDim2.fromOffset(118, 40),
    BackgroundTransparency = 1,
}, accessCard)
local premiumButton = makeButton(plansSlot, "PremiumPlans", "View Plans", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), COLORS.premiumAction, COLORS.premiumHover, COLORS.premiumPressed, "external-link")
setButtonTextSize(premiumButton, 12)
local plansScale = create("UIScale", { Scale = 1 }, plansSlot)
local plansMotionStartedAt = os.clock()
track(RunService.RenderStepped:Connect(function()
    local phase = os.clock() - plansMotionStartedAt
    premiumButton.Position = UDim2.fromOffset(
        math.cos(phase * 0.90) * 2.0,
        math.sin(phase * 1.10) * 3.0
    )
    premiumButton.Rotation = math.sin(phase * 0.74 + 0.55) * 0.65
    plansScale.Scale = 1 + math.sin(phase * 0.62 + 1.20) * 0.012
end))

local lastErrorDetail = ""
local function replacePlain(value, needle, replacement)
    if needle == "" then return value end
    local pieces = {}
    local cursor = 1
    while true do
        local first, last = value:find(needle, cursor, true)
        if not first then
            table.insert(pieces, value:sub(cursor))
            break
        end
        table.insert(pieces, value:sub(cursor, first - 1))
        table.insert(pieces, replacement)
        cursor = last + 1
    end
    return table.concat(pieces)
end

-- `key` is passed explicitly because the input box is cleared before the loader runs
local function sanitizeDiagnostic(value, key)
    local detail = tostring(value or "")
    local rawKey = tostring(key or input.Text or "")
    local normalizedKey = normalizeKey(rawKey)
    if rawKey ~= "" then
        detail = replacePlain(detail, rawKey, "[key redacted]")
    end
    if normalizedKey ~= "" and normalizedKey ~= rawKey then
        detail = replacePlain(detail, normalizedKey, "[key redacted]")
    end
    return trim((detail:gsub("[%c]+", " "):gsub("%s+", " ")))
end

local function setStatusLayout(hasDetail, tone)
    local statusHeight = hasDetail and 82 or 46
    local accessY = hasDetail and 478 or 442
    local accessHeight = hasDetail and 110 or 146
    statusDetail.Visible = hasDetail
    copyError.Visible = hasDetail
    switchScript.Visible = not hasDetail and #candidates > 1
    premiumPerks.Visible = not hasDetail
    playTween(statusCard, MOTION.normal, {
        Size = UDim2.new(1, -40, 0, statusHeight),
    })
    playTween(accessCard, MOTION.normal, {
        Position = UDim2.fromOffset(20, accessY),
        Size = UDim2.new(1, -40, 0, accessHeight),
    })
    playTween(statusSummary, MOTION.quick, {
        Position = UDim2.fromOffset(42, hasDetail and 8 or 13),
        Size = UDim2.new(1, (hasDetail or #candidates > 1) and -160 or -58, 0, 20),
        TextColor3 = tone,
    })
    playTween(statusIcon, MOTION.quick, {
        Position = UDim2.fromOffset(16, hasDetail and 10 or 15),
    })
end

local function setStatus(message, color, detail, key)
    local tone = color or COLORS.textMuted
    local safeDetail = sanitizeDiagnostic(detail, key)
    local hasDetail = safeDetail ~= ""
    statusSummary.Text = tostring(message or "")
    local iconName = "info"
    if tone == COLORS.success then
        iconName = "check-circle"
    elseif tone == COLORS.warning or tone == COLORS.danger then
        iconName = "alert-circle"
    end
    applyLucideData(statusIcon, iconName)
    playTween(statusIcon, MOTION.quick, { ImageColor3 = tone })
    playTween(statusAccent, MOTION.quick, { BackgroundColor3 = tone })
    setStatusLayout(hasDetail, tone)
    lastErrorDetail = safeDetail
    if hasDetail then
        statusDetail.Text = #safeDetail > 190 and (safeDetail:sub(1, 187) .. "...") or safeDetail
        warn("[SnowyHub] " .. tostring(message or "Error") .. " " .. safeDetail)
    else
        statusDetail.Text = ""
    end
end

if selected.universal then
    setStatus("Game not listed - Snowy Universal will load.", COLORS.warning)
elseif #candidates > 1 then
    setStatus(("Ready for %s (%d/%d). Not loading? Switch script."):format(selected.name, candidateIndex, #candidates), COLORS.cyan)
else
    setStatus("Ready for " .. selected.name .. ".", COLORS.cyan)
end

local busy = false
local closing = false

local function fetchLoader(entry)
    if type(loadstring) ~= "function" then
        return nil, "This executor does not support loadstring."
    end
    local ok, source = pcall(function()
        return game:HttpGet(entry.url)
    end)
    if (not ok or type(source) ~= "string" or source:find("this loader link does not exist")) and entry.id then
        local luarmorUrl = ("https://api.luarmor.net/files/v4/loaders/%s.lua"):format(entry.id)
        local lok, lsrc = pcall(function() return game:HttpGet(luarmorUrl) end)
        if lok and type(lsrc) == "string" and #lsrc > 50 and not lsrc:find("does not exist") then
            ok = true
            source = lsrc
        end
    end
    -- local fallback: check readfile if remote fetch fails or SNOWY_DEV enabled
    if (not ok or type(source) ~= "string" or source:find("this loader link does not exist"))
        and type(readfile) == "function" then
        local cleanName = (entry.name or ""):gsub("%s+", "")
        local cleanAlpha = (entry.name or ""):gsub("[%s%p]+", "")
        local candidates = {
            entry.file,
            entry.file and ("SnowyHub/" .. entry.file),
            "SnowyHub_" .. cleanName .. ".lua",
            "SnowyHub/SnowyHub_" .. cleanName .. ".lua",
            "SnowHub_" .. cleanName .. ".lua",
            "SnowyHub/SnowHub_" .. cleanName .. ".lua",
            "SnowHub_" .. cleanAlpha .. ".lua",
            "SnowyHub/SnowHub_" .. cleanAlpha .. ".lua",
            "Snowy_" .. cleanName .. ".lua",
            "SnowyHub/" .. cleanName .. ".lua",
            "SnowyHub_" .. cleanName .. "s.lua",
            "SnowyHub/SnowyHub_" .. cleanName .. "s.lua",
            "Snowy_" .. cleanName .. "s.lua",
            "SnowyHub/" .. cleanName .. "s.lua"
        }
        for _, path in ipairs(candidates) do
            if path then
                local fok, fsrc = pcall(readfile, path)
                if fok and type(fsrc) == "string" and #fsrc > 100 then
                    ok = true
                    source = fsrc
                    break
                end
            end
        end
    end
    if not ok then
        return nil, "Download failed: " .. tostring(source)
    end
    if type(source) ~= "string" or source == "" then
        return nil, "Download returned an empty response."
    end
    local chunk, compileError = loadstring(source)
    if not chunk then
        return nil, "Loader failed to compile: " .. tostring(compileError)
    end
    return chunk
end

-- forward declaration: redeemKey closes the window on success, closeLoader is assigned further down
local closeLoader

local function redeemKey()
    if busy or closing then return end
    local key = normalizeKey(input.Text)
    if key == "" then
        setStatus("Enter your FlowAuth key first.", COLORS.warning)
        return
    end

    local entry = resolveLoader()
    busy = true
    setButtonEnabled(redeem, false)
    setButtonText(redeem, "Checking...")
    setStatus("Verifying key with FlowAuth...", COLORS.cyan)

    task.spawn(function()
        local chunk, failure = fetchLoader(entry)
        if not chunk then
            busy = false
            setButtonEnabled(redeem, true)
            setButtonText(redeem, "Redeem")
            setStatus("Could not load " .. entry.name .. ".", COLORS.danger, failure, key)
            return
        end

        script_key = key
        _G.script_key = key
        if type(getgenv) == "function" then
            getgenv().script_key = key
        end

        setButtonText(redeem, "Authenticating...")
        local ok, runtimeError = pcall(chunk, key)

        if not ok then
            busy = false
            setButtonEnabled(redeem, true)
            setButtonText(redeem, "Redeem")

            local rawErr = tostring(runtimeError or "")
            local errLower = rawErr:lower()

            if errLower:find("invalid_key") or (errLower:find("invalid") and errLower:find("key")) then
                setStatus("Invalid Key: The key you entered is not recognized.", COLORS.danger, "The script key is invalid. Please check your spelling or get a new key from Discord.", key)
            elseif errLower:find("hwid_mismatch") or errLower:find("hwid_locked") or errLower:find("hwid") then
                setStatus("HWID Locked: Key is locked to another device.", COLORS.danger, "This key is HWID locked to a different device. Reset your HWID on Discord or contact support.", key)
            elseif errLower:find("key_expired") or errLower:find("expired") then
                setStatus("Key Expired: Your key has expired.", COLORS.warning, "This key has expired. Please visit Discord or our pricing page to renew.", key)
            elseif errLower:find("blacklisted") or errLower:find("banned") then
                setStatus("Key Blacklisted: This key has been revoked.", COLORS.danger, "This key has been revoked by administrators.", key)
            elseif errLower:find("rate_limit") or errLower:find("too many") then
                setStatus("Rate Limited: Too many key requests.", COLORS.warning, "Please wait a moment before trying to redeem again.", key)
            elseif errLower:find("timeout") or errLower:find("timed out") or errLower:find("download failed") then
                setStatus("Connection Error: FlowAuth server timed out.", COLORS.warning, "Could not reach FlowAuth servers. Please check your connection and try again.", key)
            else
                setStatus("Script failed to start", COLORS.danger, rawErr, key)
            end
            warn("[SnowyHub] " .. entry.name .. " authentication failed: " .. sanitizeDiagnostic(rawErr, key))
            return
        end

        -- Key is valid and script was successfully launched!
        setStatus("Authenticated! Loading " .. entry.name .. "...", COLORS.success)
        setButtonText(redeem, "Loaded")

        pcall(function()
            if writefile then
                writefile("SnowyHub_Key.txt", key)
            end
        end)

        busy = false
        task.delay(0.35, function()
            closeLoader()
        end)
    end)
end
copyError.Activated:Connect(function()
    if lastErrorDetail ~= "" and copyText(lastErrorDetail) then
        setButtonText(copyError, "Copied")
        task.delay(1.2, function()
            if copyError.Parent then setButtonText(copyError, "Copy Error") end
        end)
    else
        warn("[SnowyHub] Clipboard API unavailable; read the full error above in the executor console.")
    end
end)

getKey.Activated:Connect(function()
    if copyText(DISCORD_URL) then
        setStatus("Discord link copied - get your key there.", COLORS.success)
    else
        setStatus(DISCORD_URL, COLORS.warning)
    end
end)

discord.Activated:Connect(function()
    if copyText(DISCORD_URL) then
        setStatus("Discord invite copied.", COLORS.success)
    else
        setStatus(DISCORD_URL, COLORS.warning)
    end
end)

copyHwid.Activated:Connect(function()
    local hwid = readableHwid()
    if hwid and copyText(hwid) then
        setStatus("HWID copied.", COLORS.success)
    else
        setStatus("FlowAuth will bind your HWID automatically.", COLORS.warning)
    end
end)

switchScript.Activated:Connect(function()
    if busy or closing or #candidates < 2 then return end
    candidateIndex = candidateIndex % #candidates + 1
    local entry = resolveLoader()
    if gameValueLabel then
        gameValueLabel.Text = gameLabel()
    end
    pcall(function()
        if type(writefile) == "function" then
            writefile(PICK_FILE, entry.id)
        end
    end)
    setStatus(("Switched to %s (%d/%d)."):format(entry.name, candidateIndex, #candidates), COLORS.cyan)
end)

premiumButton.Activated:Connect(function()
    if copyText(PRICING_URL) then
        setStatus("Pricing link copied.", COLORS.success)
    else
        setStatus(PRICING_URL, COLORS.warning)
    end
end)

input.Focused:Connect(function()
    inputFocused = true
    if input.Text == "" then
        input.PlaceholderText = "Paste your FlowAuth key"
    end
    playTween(input, MOTION.quick, { BackgroundColor3 = COLORS.inputFocus })
    playTween(inputBorder, MOTION.quick, { Transparency = 0.06 })
    playTween(inputKeyIcon, MOTION.quick, { ImageColor3 = COLORS.cyan })
end)

input.FocusLost:Connect(function(enterPressed)
    inputFocused = false
    playTween(input, MOTION.quick, { BackgroundColor3 = COLORS.input })
    playTween(inputBorder, MOTION.quick, { Transparency = 0.18 })
    playTween(inputKeyIcon, MOTION.quick, { ImageColor3 = COLORS.textMuted })
    if enterPressed then
        redeemKey()
    end
end)

local waitingKeyStates = {
    "Waiting for key",
    "Waiting for key.",
    "Waiting for key..",
    "Waiting for key...",
}
task.spawn(function()
    local waitingIndex = 1
    while gui.Parent do
        if input.Text == "" and not inputFocused then
            input.PlaceholderText = waitingKeyStates[waitingIndex]
            waitingIndex = waitingIndex % #waitingKeyStates + 1
        end
        task.wait(0.45)
    end
end)

local detailsVisible = true
local requestedDetails = true
local viewportCompact = false
local detailsTransitioning = false
local detailsTransitionVersion = 0
local updateResponsiveScale

local function setDetailsVisible(visible, announce)
    visible = visible and not viewportCompact
    setSnowflakeCount(visible and DESKTOP_SNOWFLAKES or COMPACT_SNOWFLAKES)
    -- already heading to this state: don't restart (restarting snapped the panel back to -286 on every resize event)
    if visible == detailsVisible then
        return
    end

    detailsTransitionVersion = detailsTransitionVersion + 1
    local transitionVersion = detailsTransitionVersion
    detailsTransitioning = true
    detailsVisible = visible

    columnDivider.Visible = true
    if visible then
        if not userPanel.Visible then
            userPanel.Visible = true
            userPanel.Position = UDim2.fromOffset(-286, 8)
            columnDivider.BackgroundTransparency = 1
        end
        playTween(shell, MOTION.slow, {
            Size = UDim2.fromOffset(DESKTOP_WIDTH, SHELL_HEIGHT),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "layout")
        playTween(mainPanel, MOTION.slow, {
            Position = UDim2.fromOffset(294, 8),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        playTween(columnDivider, MOTION.slow, {
            BackgroundTransparency = 0.84,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        local profileTween = playTween(userPanel, MOTION.slow, {
            Position = UDim2.fromOffset(8, 8),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        profileTween.Completed:Connect(function()
            if transitionVersion == detailsTransitionVersion then
                detailsTransitioning = false
            end
        end)
    else
        playTween(shell, MOTION.slow, {
            Size = UDim2.fromOffset(COMPACT_WIDTH, SHELL_HEIGHT),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "layout")
        playTween(mainPanel, MOTION.slow, {
            Position = UDim2.fromOffset(8, 8),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        playTween(columnDivider, MOTION.slow, {
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        local profileTween = playTween(userPanel, MOTION.slow, {
            Position = UDim2.fromOffset(-286, 8),
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, "details")
        profileTween.Completed:Connect(function()
            if gui.Parent and transitionVersion == detailsTransitionVersion and not detailsVisible then
                userPanel.Visible = false
                columnDivider.Visible = false
                detailsTransitioning = false
            end
        end)
    end
    if announce then
        setStatus(visible and "Profile details shown." or "Compact mode enabled.", COLORS.textMuted)
    end
    if updateResponsiveScale then
        task.defer(updateResponsiveScale)
    end
end

settingsButton.Activated:Connect(function()
    if detailsTransitioning then return end
    if viewportCompact then
        setStatus("Profile is hidden on compact screens.", COLORS.warning)
        return
    end
    requestedDetails = not requestedDetails
    setDetailsVisible(requestedDetails, true)
end)

minimize.Activated:Connect(function()
    if detailsTransitioning then return end
    requestedDetails = false
    setDetailsVisible(false, true)
end)

closeLoader = function()
    if closing or busy then return end
    closing = true
    playTween(backdrop, MOTION.normal, { BackgroundTransparency = 1 })
    playTween(shellScale, MOTION.normal, { Scale = shellScale.Scale * 0.96 })
    local tween = playTween(shell, MOTION.normal, { GroupTransparency = 1 }, nil, nil, "visibility")
    tween.Completed:Connect(function()
        if gui.Parent then gui:Destroy() end
    end)
end

close.Activated:Connect(closeLoader)
redeem.Activated:Connect(redeemKey)

local startedAt = os.clock()
task.spawn(function()
    while gui.Parent do
        local elapsed = math.floor(os.clock() - startedAt)
        sessionText.Text = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)
        local ping = "--"
        pcall(function()
            ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():match("[%d%.]+") or "--"
        end)
        pingText.Text = tostring(ping) .. " ms"
        task.wait(1)
    end
end)

local dragging = false
local dragStart
local shellStart
header.InputBegan:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inputObject.Position
        shellStart = shell.Position
    end
end)
track(UserInputService.InputEnded:Connect(function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))
track(UserInputService.InputChanged:Connect(function(inputObject)
    if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
        local delta = inputObject.Position - dragStart
        shell.Position = UDim2.new(
            shellStart.X.Scale,
            shellStart.X.Offset + delta.X,
            shellStart.Y.Scale,
            shellStart.Y.Offset + delta.Y
        )
    end
end))

local entered = false
local responsiveScale = 1
local function currentViewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

updateResponsiveScale = function()
    local viewport = currentViewport()
    local baseWidth = detailsVisible and DESKTOP_WIDTH or COMPACT_WIDTH
    responsiveScale = math.min(
        1,
        math.max(0.42, (viewport.X - 24) / baseWidth),
        math.max(0.42, (viewport.Y - 24) / SHELL_HEIGHT)
    )
    if entered then
        playTween(shellScale, MOTION.normal, { Scale = responsiveScale })
    else
        shellScale.Scale = responsiveScale * 0.96
    end
end

local function applyResponsiveLayout()
    if not gui.Parent then return end
    viewportCompact = currentViewport().X < 860
    setDetailsVisible(requestedDetails and not viewportCompact, false)
    updateResponsiveScale()
end

-- CurrentCamera can be swapped out; rebind the viewport listener when it is
local viewportConnection
local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
    end
    applyResponsiveLayout()
end
track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera))
gui.Destroying:Connect(function()
    if viewportConnection then
        viewportConnection:Disconnect()
    end
end)
bindCamera()

-- Auto-load previously saved key if available
pcall(function()
    if type(readfile) == "function" then
        local hasFile = false
        if type(isfile) == "function" then
            hasFile = isfile("SnowyHub_Key.txt")
        else
            local ok, test = pcall(readfile, "SnowyHub_Key.txt")
            hasFile = ok and type(test) == "string"
        end
        if hasFile then
            local savedKey = readfile("SnowyHub_Key.txt")
            if type(savedKey) == "string" and #trim(savedKey) > 0 then
                input.Text = trim(savedKey)
            end
        end
    end
end)

task.defer(function()
    if not gui.Parent then return end
    entered = true
    playTween(backdrop, MOTION.slow, { BackgroundTransparency = 0.78 })
    playTween(shell, MOTION.slow, { GroupTransparency = 0 }, nil, nil, "visibility")
    playTween(shellScale, MOTION.slow, { Scale = responsiveScale })
end)
"