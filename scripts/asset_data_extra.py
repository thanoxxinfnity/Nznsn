# make_asset_list2.py ke liye extra sections. Format: prio|name|variants|size_m|tris|prompt[|R]
SECTIONS_EXTRA = [
("CV", "Cars & vehicles: intact variety", "City", """
P2|Old sedan|3|4.4|15000|3 variants old boxy Indian sedan, faded paint, dusty, intact
P2|Small hatchback|2|3.6|12000|2 variants small old hatchback car, intact
P2|Open jeep|1|3.8|14000|old open jeep, intact
P2|Taxi black-yellow|1|4.2|15000|old black-and-yellow taxi, no text
P2|Pickup truck|1|5.0|16000|old pickup truck with open bed
P2|Minivan|1|4.6|15000|old minivan with sliding door
P3|Station wagon|1|4.6|15000|old station wagon
P3|Luxury old car|1|4.8|16000|old luxury sedan with chrome, faded
P3|Mini goods truck (tempo)|1|4.5|14000|small three-wheel goods tempo
P3|Tractor|1|3.5|14000|old farm tractor
P3|Hearse|1|5.2|16000|old black hearse, dusty
P3|Ice-cream van|1|5.0|16000|old ice-cream van, faded cartoon colors, no text
P3|Mail van|1|4.8|15000|old mail van, no text
P3|Vegetable truck|1|7.0|20000|old open truck with wooden sides
P3|Water tanker|1|7.0|20000|old water tanker truck
P3|Road roller|1|4.0|14000|old road roller
P3|Vespa-style scooter|1|1.8|9000|old Italian-style scooter
P3|Bullock cart|1|3.0|8000|wooden bullock cart without animal
P4|Horse carriage|1|4.0|12000|old horse carriage, no horse
P4|Large ride-on toy car|1|1.2|5000|large kid's ride-on toy car, faded
P4|Pedal car|1|1.2|4000|old kid's pedal car
"""),
("JV", "Wrecks & junkyard (toota-foota gaadiyan)", "City / Junkyard", """
P2|Crashed car (front smashed)|3|4.4|15000|3 variants old car crashed into a pole, hood crumpled, glass broken
P2|Burnt-out car shell|3|4.4|14000|3 variants burnt-out car shell, blackened, no tyres
P2|Overturned car|2|4.4|14000|2 variants car overturned on its roof
P2|Car on bricks, hood open|2|4.4|14000|abandoned car on bricks, hood open, wheels missing
P2|Car with smashed windows|3|4.4|14000|3 variants abandoned car with smashed windows, flat tyres
P2|Rusted overgrown car|2|4.4|14000|rusty car covered with vines and weeds
P2|Head-on collision pair|1|8.0|28000|two old cars crashed head-on, interlocked
P2|Wrecked city bus|2|10.0|26000|2 variants wrecked city bus, windows smashed, tilted
P3|Wrecked truck|2|7.0|20000|2 variants wrecked truck, cargo spilled
P3|Wrecked auto-rickshaw|2|3.0|10000|2 variants overturned crushed rickshaw
P3|Wrecked motorcycle|2|2.0|8000|2 variants crashed motorcycles
P3|Bent bicycle|2|1.8|5000|2 variants bent bicycles
P3|Detached car doors|3|1.2|2500|3 variants detached car doors
P3|Detached car hood|2|1.4|2000|2 variants detached car hoods
P3|Worn tyres|3|0.7|1500|3 variants worn tyres, single and stacked
P3|Car wheel rims|2|0.7|1500|2 variants rims
P3|Exposed engine block|1|0.8|4000|exposed car engine block
P3|Torn car seats|2|0.7|2500|2 variants torn car seats
P3|Steering wheel|1|0.4|1500|old steering wheel
P3|Bumper pieces|3|1.5|1500|3 variants bumpers
P3|Smashed windshield frame|1|1.4|2000|smashed windshield frame
P3|Exhaust pipe|1|1.2|1000|exhaust pipe
P3|Tyre stacks|2|1.2|2500|2 variants stacks of tyres
P3|Scrap metal piles|3|1.5|2500|3 variants scrap metal piles
P3|Oil puddle flat|1|1.0|300|flat oil puddle
P3|Car jack|1|0.6|2000|old car jack
P3|Old tow truck|1|7.0|22000|old tow truck
P4|Crushed car cubes stack|1|3.0|9000|stack of crushed car cubes
P4|Car crusher machine|1|5.0|16000|junkyard car crusher
P4|Junkyard sheet-metal gate|1|5.0|4000|junkyard sheet-metal gate
P4|Wrecked ambulance|1|5.0|18000|wrecked ambulance
P4|Wrecked fire truck|1|8.0|22000|wrecked fire truck
P4|Wrecked police car|1|4.5|15000|wrecked police car
P4|Derailed tram|1|12.0|28000|derailed tram tilted
P4|Wrecked school bus|1|9.0|24000|wrecked yellow school bus
P4|Burnt bus shell|1|10.0|24000|burnt bus shell
P4|Burnt truck shell|1|7.0|20000|burnt truck shell
"""),
("BR", "Broken & damaged props (toota-foota saman)", "All", """
P2|Broken chair|4|0.9|2500|4 variants broken chairs, legs snapped
P2|Broken table|3|1.2|3500|3 variants broken tables
P2|Broken door hanging|3|2.2|3000|3 variants broken door hanging off one hinge, door leaf only
P2|Broken window with glass|2|1.5|2500|2 variants broken window frames with glass
P2|Smashed CRT television|2|0.8|3500|2 variants smashed old televisions
P2|Smashed monitor|1|0.5|2500|smashed CRT monitor
P2|Collapsed shelf|2|1.8|4000|2 variants collapsed shelves with fallen items
P2|Cracked mirror|3|1.0|2000|3 variants cracked mirrors
P2|Broken bed frame|2|2.0|4500|2 variants broken bed frames
P2|Torn mattress|2|1.9|2500|2 variants torn mattresses
P2|Ripped sofa|2|2.0|5500|2 variants ripped sofa
P3|Smashed vending machine|1|1.8|7000|smashed vending machine
P3|Bent street lamp|2|5.0|3500|2 variants bent street lamps
P3|Fallen signboard|3|2.0|1500|3 variants fallen blank signboards
P3|Broken wooden fence|2|3.0|2000|2 variants broken wooden fence
P3|Cracked wall panel|3|3.0|1500|3 variants wall segments with big cracks
P3|Cracked floor slab|3|3.0|1000|3 variants cracked floor slabs
P3|Collapsed ceiling piece|2|3.0|3000|2 variants collapsed ceiling pieces with hanging wires
P3|Broken stairs|2|3.0|3500|2 variants broken stairs
P3|Broken railing|3|2.0|1500|3 variants broken railings
P3|Bent metal sheet|3|1.5|1200|3 variants bent metal sheets
P3|Torn tent|1|4.0|3000|torn tent collapsed
P3|Broken piano|1|1.6|8000|broken piano with missing keys
P3|Broken clock|2|0.6|2000|2 variants broken clocks
P3|Smashed dollhouse|1|0.8|6000|smashed dollhouse
P3|Smashed toy box|1|0.6|2500|smashed toy box
P3|Broken fridge open|1|1.7|5000|broken fridge door hanging open
P3|Broken toilet|1|0.8|3000|broken toilet
P3|Broken sink|1|0.8|2500|broken sink
P3|Cracked bathtub|1|1.7|4500|cracked bathtub
P3|Broken glass table|1|1.2|2500|broken glass-top table
P3|Broken lamp|3|0.5|1200|3 variants broken lamps
P3|Cracked pots|4|0.4|1200|4 variants cracked clay pots
P3|Smashed crates|3|0.8|1500|3 variants smashed wooden crates
P3|Collapsed scaffolding|1|3.0|4000|collapsed scaffolding
P3|Fallen bookcase|1|1.8|4000|fallen bookcase with books
P3|Torn curtain rod|1|2.0|1200|torn curtain and bent rod
P4|Burnt furniture|4|1.0|2500|4 variants burnt black furniture pieces
P4|Burnt doll|3|0.4|3500|3 variants burnt dolls
P4|Melted toys pile|2|0.5|3000|2 variants piles of melted toys
P4|Flooded rubble|1|2.0|2500|rubble half under dark water
"""),
("NT", "Nature & outdoors", "Outdoors", """
P2|Dead tree|5|6.0|7000|5 variants twisted bare dead trees
P2|Overgrown bush|4|1.5|3000|4 variants overgrown bushes
P2|Tall grass clump|4|1.0|1500|4 variants tall grass clumps
P2|Rocks|5|1.0|2500|5 variants rocks
P2|Boulders|3|2.5|3500|3 variants big boulders
P3|Tree stump|3|0.6|2000|3 variants tree stumps
P3|Fallen log|3|2.5|2500|3 variants fallen logs
P3|Dead hedge|2|2.0|2500|2 variants dead hedges
P3|Thorn bushes|2|1.0|2500|2 variants thorn bushes
P3|Vine-covered wall piece|2|3.0|3000|2 variants wall pieces covered with vines
P3|Exposed roots|3|2.0|2500|3 variants exposed tree roots
P3|Mushrooms|3|0.3|1500|3 variants mushroom clusters
P3|Dead flowers|3|0.4|1200|3 variants dead flower clumps
P3|Dead pine tree|2|8.0|7000|2 variants dead pine trees
P3|Dead palm tree|2|7.0|6000|2 variants dead palm trees
P3|Bamboo clump|1|4.0|3500|bamboo clump
P3|Cactus|1|1.0|2000|cactus
P3|Crows perched|3|0.4|1500|3 variants crows perched, static
P3|Pigeons|2|0.3|1200|2 variants pigeons static
P3|Stray cat sitting|2|0.4|2000|2 variants stray cat sitting, static
P3|Stray dog standing|1|0.6|2500|stray dog standing, static
P3|Giant spider web|2|2.0|1000|2 variants giant spider web, thin
P3|Beehive|1|0.5|1500|abandoned beehive
P3|Bird nest|1|0.3|1000|bird nest
P3|Mud puddle|2|1.5|400|2 variants mud puddle flat
P4|Pond reeds|1|1.0|1500|pond reeds
P4|Dried grass field patch|1|2.0|2000|dried grass patch
"""),
("CS", "Construction site", "Outskirts", """
P3|Scaffolding section|3|3.0|3500|3 variants metal scaffolding sections
P3|Tower crane|1|20.0|20000|tall tower crane, rusty
P3|Cement mixer|1|2.0|6000|cement mixer
P3|Concrete barriers|3|2.0|1500|3 variants concrete barriers
P3|Traffic cones|2|0.7|600|2 variants traffic cones
P3|Sand piles|2|2.0|1000|2 variants sand piles
P3|Rebar bundle|2|3.0|1500|2 variants steel rebar bundles
P3|Brick pallet|1|1.2|2000|brick pallet
P3|Long ladder|1|4.0|2500|long ladder
P3|Site portable cabin|1|3.0|5000|portable site office cabin
P3|Excavator|1|6.0|22000|old excavator
P3|Bulldozer|1|5.0|20000|old bulldozer
P3|Dump truck|1|7.0|22000|old dump truck
P3|Jackhammer|1|0.8|2500|jackhammer
P3|Portable generator|1|0.8|3000|small portable generator
P3|Hard hats|3|0.3|1200|3 variants hard hats
P3|Barrier tape|1|3.0|300|flat barrier tape
P3|Pipes stack|1|1.5|2000|stack of pipes
P3|Concrete pipes|2|1.5|2000|2 variants large concrete pipes
P3|Fence panels|2|2.0|1500|2 variants site fence panels
P3|Floodlight tower|1|5.0|4000|floodlight tower
P3|Tool trolley|1|1.0|3000|tool trolley
P4|Unfinished building frame|1|10.0|14000|unfinished concrete building frame
P4|Rope pulley|1|1.0|2000|rope pulley
"""),
("SP", "Sports & games", "School / Park", """
P3|Cricket stumps|1|0.8|1500|cricket stumps
P3|Football goalpost|1|3.0|3000|football goalpost
P3|Basketball hoop|1|3.5|3500|basketball hoop
P3|Carrom board|1|0.8|3000|carrom board with pieces
P3|Chess set|1|0.4|3000|chess set
P3|Ludo board|1|0.5|1500|ludo board
P3|Table tennis table|1|2.5|4000|table tennis table
P3|Snooker table|1|2.5|7000|snooker table
P3|Dartboard|1|0.5|1500|dartboard
P3|Kites|3|0.8|1200|3 variants paper kites
P3|Marble bag|1|0.2|1000|marble bag
P3|Gilli danda|1|0.5|800|gilli danda
P3|Roller skates|1|0.3|2500|old roller skates
P3|Skateboard|1|0.8|2500|skateboard
P3|Badminton rackets|2|0.7|1500|2 variants badminton rackets
P3|Shuttlecock|1|0.1|500|shuttlecock
P3|Frisbee|1|0.25|600|frisbee
P3|Kite spool|1|0.2|800|kite spool
P4|Boxing gloves|1|0.3|2000|boxing gloves
P4|Punching bag|1|1.2|2500|punching bag
P4|Trophy cups|3|0.4|2000|3 variants trophy cups
P4|Medals|3|0.1|600|3 variants medals
"""),
("MU", "Musical instruments", "Entertainment / Home", """
P3|Harmonium|1|0.8|5000|old harmonium
P3|Tabla set|1|0.5|3500|tabla pair
P3|Dholak|1|0.6|3000|dholak drum
P3|Old guitar|1|1.0|4000|old guitar
P3|Violin|1|0.6|3500|violin
P3|Flute|1|0.5|1200|bamboo flute
P3|Trumpet|1|0.6|2500|trumpet
P3|Small drum kit|1|1.5|6000|small drum kit
P3|Toy snare drum|1|0.4|2000|toy snare drum
P3|Accordion|1|0.5|4000|accordion
P3|Toy cymbals|1|0.3|1200|toy cymbals
P3|Toy piano|1|0.5|3000|toy piano
P3|Music stand|1|1.2|2000|music stand
P3|Metronome|1|0.3|1500|metronome
P4|Pipe whistle|1|0.2|600|pipe whistle
P4|Bugle|1|0.4|2000|bugle
P4|Maracas|2|0.3|1000|2 variants maracas
"""),
("FD", "Food & drink props", "Home / Bazaar", """
P3|Stale bread loaf|2|0.3|1500|2 variants stale bread loaf
P3|Rotten fruits|4|0.2|1000|4 variants rotten fruits
P3|Old plates of food|3|0.3|1500|3 variants plates of old food
P3|Tin food cans|3|0.15|800|3 variants tin food cans, no text
P3|Soda bottles|3|0.3|1000|3 variants soda bottles, no text
P3|Cups of tea|2|0.1|800|2 variants cups of cold tea
P3|Cake slices|2|0.15|1000|2 variants cake slices
P3|Candy jars|2|0.3|1500|2 variants candy jars
P3|Lollipops|3|0.2|800|3 variants lollipops
P3|Chocolate wrappers|1|0.2|400|chocolate wrappers
P3|Popcorn bucket|1|0.3|1200|popcorn bucket
P3|Melted ice-cream cone|1|0.2|1000|melted ice-cream cone
P3|Pastry box|1|0.3|1200|pastry box
P3|Biscuit tin|2|0.25|1200|2 variants biscuit tins, no text
P3|Spilled cereal box|1|0.3|1000|spilled cereal box
P3|Laddoo pile|1|0.3|1500|pile of laddoo sweets
P4|Milk bottles|3|0.25|1000|3 variants milk bottles
P4|Egg tray|1|0.3|1200|egg tray
P4|Cooking oil tin|1|0.35|1200|cooking oil tin, no text
P4|Sugar sacks|2|0.5|1500|2 variants sugar sacks
"""),
("CL", "Clothing & fabric", "Home / Bazaar", """
P3|Hanging dress|3|1.0|3000|3 variants dresses on hangers
P3|Child's frock|3|0.6|2500|3 variants small child frocks
P3|Hanging shirts|3|0.7|2500|3 variants shirts on hangers
P3|Draped sari|1|1.5|3500|sari draped on a stand
P3|Rolled blankets|3|0.6|1500|3 variants rolled blankets
P3|Torn bed sheets|2|2.0|1500|2 variants torn bed sheets
P3|Scarf|2|1.0|1200|2 variants scarves
P3|Gloves pair|2|0.25|1000|2 variants gloves
P3|Socks|2|0.2|600|2 variants socks
P3|Baby bib|1|0.2|500|baby bib
P3|School tie|1|0.5|600|school tie
P3|Apron|1|0.9|1800|apron on hook
P3|Raincoat|1|1.1|2500|raincoat on hook
P3|Boots|2|0.3|1500|2 variants boots
P3|Slippers|3|0.25|800|3 variants slippers
P4|Lace curtains|1|2.0|1800|lace curtains
P4|Doll dresses|3|0.2|800|3 variants tiny doll dresses
"""),
("HM", "Heavy machinery & factory industry", "Factory / Outskirts", """
P2|Industrial loom|1|3.0|10000|large industrial loom
P2|Injection molding machine|1|3.5|14000|plastic injection molding machine
P2|Plastic extruder|1|3.0|10000|plastic extruder
P2|Paint booth|1|3.0|8000|toy painting booth
P2|Assembly line module|2|3.0|6000|2 variants assembly line modules with clamps
P2|Packaging machine|1|2.5|8000|packaging machine
P3|Boiler|1|3.0|8000|industrial boiler
P3|Air compressor|1|1.5|6000|air compressor
P3|Lathe|1|2.0|7000|metal lathe
P3|Drill press|1|1.5|4000|drill press
P3|Welding station|1|1.5|4000|welding station
P3|Gas cylinder trolley|1|1.2|3000|gas cylinder trolley
P3|Overhead pipe rack|1|3.0|4000|overhead pipe rack
P3|Factory smokestack|1|15.0|8000|tall brick smokestack
P3|Storage tank|2|5.0|8000|2 variants large storage tanks
P3|Cooling tower|1|10.0|10000|cooling tower
P3|Factory gate|1|6.0|6000|large factory gate, no text
P3|Loading dock|1|4.0|7000|loading dock
P3|Roller conveyor|1|2.0|3000|roller conveyor
P3|Material hopper|1|2.5|5000|hopper
P3|Steel beams pile|2|3.0|2500|2 variants steel beam piles
P3|Chain hoist|1|1.0|3500|chain hoist
P4|Shipping container|2|6.0|4000|2 variants rusty shipping containers
P4|Weighbridge|1|6.0|5000|weighbridge
"""),
("TY", "More toys (bahut saare khilaune)", "All", """
P2|Large retro toy robot|2|0.6|7000|2 variants large retro toy robots
P2|Toy telephone|1|0.3|2500|pull toy phone with eyes
P2|Pull-along duck|1|0.4|3000|wooden pull-along duck
P2|Toy drum|1|0.3|2000|toy drum with sticks
P2|Toy trumpet|1|0.3|1500|toy trumpet
P2|Spinning carousel toy|1|0.4|4000|spinning carousel music toy
P2|Toy castle|1|0.8|7000|toy castle
P2|Toy fort with soldiers|1|0.8|6000|toy fort with soldiers
P2|Toy farm set|1|0.6|5000|toy farm set
P2|Wooden toy animals|6|0.2|2000|6 variants wooden toy animals
P2|Plush animals|6|0.4|4000|6 variants plush toys (lion, panda, dog, cat, penguin, giraffe)
P2|Toy kitchen set|1|0.6|5000|toy kitchen set
P2|Toy doctor kit|1|0.3|2500|toy doctor kit
P2|Toy tea set|1|0.3|2500|toy tea set
P2|Toy block towers|2|0.5|3000|2 variants toy block towers
P2|Pop-up toy|1|0.3|3000|pop-up toy
P3|Stacking rings|1|0.3|2000|stacking rings toy
P3|Shape sorter|1|0.3|2500|shape sorter toy
P3|Bouncy balls|3|0.15|600|3 variants bouncy balls
P3|Yo-yo|2|0.1|600|2 variants yo-yo
P3|Toy bus|1|0.4|3000|toy bus
P3|Toy airplane|2|0.4|3000|2 variants toy airplanes
P3|Toy boat|1|0.4|2500|toy boat
P3|Toy helicopter|1|0.3|2500|toy helicopter
P3|Toy dinosaur|3|0.4|3500|3 variants toy dinosaurs
P3|Action figure|3|0.3|3000|3 variants action figures
P3|Fashion doll|3|0.3|4000|3 variants fashion dolls
P3|Baby doll|3|0.4|4500|3 variants baby dolls
P3|Doll stroller|1|0.5|3000|doll stroller
P3|Dollhouse furniture|4|0.15|1200|4 variants dollhouse furniture sets
P3|Toy train track|1|1.5|2500|toy train track
P3|Cap gun|1|0.2|1500|toy cap gun
P3|Kaleidoscope|1|0.3|2000|kaleidoscope
P3|Magic 8 ball|1|0.1|800|magic 8 ball
P3|Pinwheel|2|0.3|1200|2 variants pinwheels
P3|Whistle toy|1|0.1|500|toy whistle
P3|Rattle|2|0.2|1200|2 variants baby rattles
P3|Teething ring|1|0.1|600|teething ring
P3|Musical cot mobile|1|0.5|2500|musical cot mobile
P3|Toy hammer|1|0.3|1000|toy hammer
P3|Water gun|1|0.3|1500|water gun
P3|Toy camera|1|0.2|1500|toy camera
P3|Building bricks pile|1|0.4|2500|pile of plastic building bricks
P3|Modelling clay tubs|1|0.2|1000|modelling clay tubs
P3|Coloring books|3|0.25|600|3 variants coloring books, no readable text
P3|Sticker book|1|0.2|500|sticker book
P4|Giant plush bear|1|2.0|9000|giant plush bear
P4|Giant jack-in-the-box|1|2.5|9000|giant jack-in-the-box
P4|Giant wind-up key|1|1.0|3000|giant wind-up key
"""),
("ST", "Street furniture & signage extras", "City", """
P3|Street clock pole|1|4.0|4000|street clock on pole, stopped
P3|Public telephone|1|1.8|3500|public telephone box
P3|Post box|1|1.4|3000|old post box
P3|Concrete bench|1|2.0|2000|concrete bench
P3|Bollards|2|1.0|1000|2 variants bollards
P3|Planters|3|1.0|2000|3 variants dead planters
P3|Trash cans|3|0.8|1500|3 variants trash cans
P3|Bus-stop sign|1|3.0|1200|bus-stop sign, symbols only
P3|Direction signboards|3|3.0|1500|3 variants direction signboards, symbols only
P3|Double streetlight|1|6.0|4500|double-arm streetlight
P3|Hoarding stand|1|8.0|4000|large hoarding stand
P3|Cable drum|1|1.0|1500|cable drum
P3|Open manhole|1|0.8|1000|open manhole
P3|Storm drain|1|1.5|1500|storm drain grate
P3|Speed breaker|1|3.0|500|speed breaker
P3|Lane divider|1|3.0|800|lane divider
P3|Pedestrian bridge|1|15.0|10000|pedestrian overhead bridge
P3|Underpass sign|1|2.0|1200|underpass sign, symbols only
P3|Large iron gate|2|3.5|5000|2 variants large iron gates
P3|Boundary wall segment|3|3.0|1500|3 variants boundary wall segments
P3|Garage shutter|1|3.0|3000|garage shutter half open
P3|Parking meter|2|1.3|1500|2 variants parking meters
P3|Bike stand|1|2.0|2000|bike stand
P3|Street ice box|1|1.0|2000|street ice box
P4|Wall graffiti panels|3|2.0|600|3 variants flat wall graffiti panels (symbols only, no text)
P4|Paste-up poster sheets|3|1.0|400|3 variants flat paste-up poster sheets, no text
P4|Torn banner|2|4.0|1500|2 variants torn banners, no text
P4|String lights|1|6.0|1500|string lights
"""),
]
