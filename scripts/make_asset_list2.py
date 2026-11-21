#!/usr/bin/env python3
"""Bada game: purani 178 items + ~480 nayi (interiors, bazaar, lab, cinema, vehicles, monsters...) -> docs/ASSET_LIST.csv + docs/KHILAUNA_NAGAR_ALL_3D_MODELS_v2.md
Format: prio|name|variants|size_m|tris|prompt[|R]   (R = rig/animation chahiye)"""
import csv, re
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
OLD = set("MFTGSHCRA")
SECTIONS = [
("L", "Ghar: living room & furniture", "Housing colony", """
P2|Sofa 3-seater|2|2.0|6000|old worn 3-seater sofa, torn fabric, springs showing
P2|Armchair|2|0.9|4000|old armchair with lace doily, stained
P2|Coffee table|1|1.0|2500|low wooden coffee table with cup rings
P2|Old television on stand|1|0.8|5000|1980s CRT television on wooden stand with antenna
P2|Valve radio|1|0.4|2500|old wooden valve radio with dial
P2|Floor lamp|1|1.6|2500|standing floor lamp with fabric shade, tilted
P2|Floor rug|3|2.0|1500|3 variants worn patterned floor rugs, thin flat mesh
P2|Window curtains|2|2.0|2500|2 variants heavy dusty curtains, torn, hanging from rod
P2|Wall photo frames set|3|0.8|1500|3 variants group of framed family photos on wall, faded
P2|Dining table|1|1.6|4000|wooden dining table with scratches
P2|Dining chair|3|0.9|2500|3 variants wooden dining chairs, one broken
P2|Steel almirah|1|1.8|5000|old steel almirah with door slightly open
P2|Wooden diwan|1|1.8|5000|wooden diwan with thin mattress and cushions
P2|Home bookshelf|2|1.8|5000|2 variants wooden bookshelf with old books and trinkets
P2|Sideboard cabinet|1|1.5|5000|wooden sideboard with glass doors and china
P3|Ceiling fan|1|1.2|3000|old three-blade ceiling fan, dusty
P3|Table fan|1|0.5|2500|old metal table fan
P3|Air cooler|1|0.9|4000|desert air cooler, rusty
P3|Pendulum wall clock|1|0.6|3000|wooden pendulum wall clock
P3|Telephone table|1|0.7|3000|small table with telephone and notepad
P3|Shoe rack|1|1.0|3000|wooden shoe rack with old shoes
P3|Coat stand|1|1.8|2500|wooden coat stand with hanging coats
P3|Wall mirror|2|1.0|2000|2 variants ornate wall mirrors, cracked
P3|Upright piano|1|1.6|10000|old upright piano, keys yellowed
P3|Sewing basket|1|0.4|2000|woven sewing basket with threads
P3|Dead flower vase|2|0.4|1500|2 variants vase with dried dead flowers
P3|Stool|2|0.5|1500|2 variants small wooden stools
P3|Folding chair|1|0.9|2000|metal folding chair
P3|Plastic chair|2|0.9|2000|2 variants worn plastic chairs
P3|Wall shelf with knick-knacks|1|1.0|3000|wall shelf with small figurines and clay toys
P3|Gramophone|1|0.6|5000|old gramophone with horn, record on turntable
P3|Hand fan|1|0.4|1000|palm-leaf hand fan
P3|Empty birdcage|1|0.5|2500|empty hanging birdcage, door open
P3|Wall calendar|1|0.4|800|old paper wall calendar, no readable text
"""),
("B", "Ghar: bedroom & bathroom", "Housing colony", """
P2|Double bed|2|2.0|6000|old wooden double bed with rumpled sheets
P2|Single bed|2|1.9|5000|metal-frame single bed with thin mattress
P2|Bunk bed|1|2.0|7000|wooden kids bunk bed with ladder
P2|Wooden wardrobe|2|2.0|6000|tall wooden wardrobe with mirror door ajar
P2|Dressing table with mirror|1|1.4|5000|vintage dressing table with oval mirror and perfume bottles
P2|Nightstand|2|0.5|2500|bedside table with lamp and glass of water
P2|Baby crib|1|1.0|5000|wooden baby crib, mobile hanging, empty
P2|Toy chest|2|0.8|3500|wooden toy chest with open lid, toys spilling
P3|Pillow and blanket pile|3|0.6|1500|3 variants rumpled pillow and blanket
P3|Kids study desk|1|1.0|3500|small kid's wooden study desk with drawings
P3|Kids wardrobe|1|1.4|4000|painted kids wardrobe with animal stickers peeling
P3|Small cradle|1|0.9|4000|small wooden rocking baby cradle
P3|Indoor clothes line|1|2.0|2000|clothes line with hanging old clothes
P3|Old suitcase|3|0.6|2500|3 variants old leather suitcases, one open
P3|School uniform on hanger|1|0.8|2000|kid's school uniform hanging
P3|Toilet|2|0.8|4000|2 variants old toilets, stained
P3|Wash basin|2|0.8|3500|2 variants wall wash basin with tap, rust stains
P3|Bathtub|1|1.7|6000|old cast-iron bathtub, dirty
P3|Bathroom mirror cabinet|1|0.6|3000|metal bathroom mirror cabinet, door open
P3|Bucket and mug|1|0.5|2000|plastic bucket and mug
P3|Shower head and pipe|1|0.6|1500|wall shower head with pipe
P3|Towel rack with towel|1|0.8|1800|towel rail with damp towel
P3|Soap dish and soap|1|0.15|600|soap dish with cracked soap
P3|Toothbrush cup|1|0.15|600|steel cup with toothbrushes
P3|Laundry basket|1|0.6|2000|woven laundry basket with clothes
P4|Small rocking horse|1|0.6|4000|small painted rocking horse
P4|Teddy on pillow|1|0.4|3000|teddy bear sitting on pillow
P4|Star night lamp|1|0.25|1500|child's star-shaped night lamp
"""),
("K", "Ghar: kitchen & dining", "Housing colony", """
P2|Gas stove|1|0.7|3500|old two-burner gas stove with cylinder
P2|Old refrigerator|1|1.7|6000|1980s rounded fridge, rusty, door ajar
P2|Kitchen sink with counter|1|1.6|5000|steel kitchen sink with counter and taps
P2|Utensil shelf|1|1.2|4000|wall rack with steel utensils
P3|Pressure cooker|1|0.3|2000|aluminium pressure cooker, dented
P3|Kadhai wok|1|0.4|1500|iron kadhai on stand
P3|Tiffin box|1|0.2|1500|stacked steel tiffin carrier
P3|Water pot matka|1|0.5|1800|clay water pot with lid
P3|Small kitchen table|1|1.0|3000|small wooden kitchen table
P3|Kettle|1|0.3|1500|aluminium kettle, blackened
P3|Cutting board and knife|1|0.4|1200|wooden cutting board with kitchen knife
P3|Dish rack with plates|1|0.5|2500|dish rack with steel plates and bowls
P3|Chakla belan|1|0.5|1500|wooden rolling board and pin
P3|Sil batta grinder|1|0.5|2000|stone grinding slab and roller
P3|Gas cylinder|1|0.7|2000|red LPG cylinder
P3|Masala dabba|1|0.25|2000|round steel spice box with small bowls
P3|Water filter|1|0.6|3000|old countertop water purifier
P3|Glass jars|3|0.25|1200|3 variants glass jars with dusty contents
P3|Plates and cups set|3|0.3|1500|3 variants plate and cup sets, chipped
P3|Grass broom|1|1.2|1000|traditional grass broom
P3|Dustpan|1|0.3|800|metal dustpan
P3|Milk can|1|0.5|1500|aluminium milk can with lid
P4|Stale birthday cake|1|0.3|2500|old stale birthday cake with melted candles
P4|Cake plate and fork|1|0.25|800|cake plate with fork
P4|Teapot and cups|1|0.3|2000|ceramic teapot with cups
P4|Bread basket|1|0.3|1500|woven basket with stale bread
P4|Rotten fruit bowl|1|0.3|2000|bowl of rotten fruit
P4|Baby high chair|1|0.9|3000|wooden baby high chair
"""),
("O", "Civic: office, bank, police, fire station", "Civic area", """
P2|Boardroom table|1|4.0|6000|long boardroom table with leather chairs
P2|Whiteboard|1|1.5|1500|wheeled whiteboard with faded scribbles, no readable text
P2|Wall safe|1|0.6|3500|steel wall safe, door open, empty
P2|Big floor safe|1|1.0|5000|big steel floor safe with dial
P2|Founder portrait painting|1|1.0|3000|large framed painting of an old man, eyes unsettling
P3|Typewriter|1|0.4|3500|old manual typewriter
P3|Intercom speaker|1|0.3|1500|wall intercom box with buttons
P3|Desk calendar|1|0.2|800|desk calendar block
P3|Ledger books stack|1|0.4|2000|stack of heavy ledger books
P3|Dead plant in pot|2|0.8|2500|2 variants dead potted plants
P3|Paper stacks|3|0.4|1500|3 variants messy stacks of paper
P3|Office shelf with binders|1|1.8|5000|office shelf with binders
P3|Water dispenser|1|1.2|3500|old water cooler dispenser
P3|Reception bell|1|0.15|800|brass service bell
P3|Rubber stamp and pad|1|0.15|800|rubber stamp and ink pad
P3|Photocopier|1|1.1|6000|old photocopier machine
P3|Bank teller counter|1|3.0|8000|bank teller counter with glass partition
P3|Vault door|1|2.5|12000|huge round bank vault door, open
P3|Safe deposit boxes wall|1|2.5|8000|wall of small numbered metal deposit boxes
P3|Police desk|1|1.6|5000|police station desk with lamp and radio
P3|Jail cell bars|1|2.5|5000|iron jail cell door and bars, rusty
P3|Lockup bench|1|2.0|2500|stone lockup bench with chain
P3|Notice board|1|1.2|2500|cork board with old notices, no readable text
P3|Police radio|1|0.3|2500|old police walkie-talkie
P3|Handcuffs|1|0.2|800|rusty handcuffs
P3|Fire extinguisher|1|0.6|1500|red fire extinguisher
P3|Fire axe on wall|1|0.8|1800|fire axe in wall holder
P3|Fire hose reel|1|0.7|3000|wall fire hose reel
P3|Fire helmet and coat|1|1.0|3500|old fireman helmet and coat on hook
P3|Warning signs|3|0.5|800|3 variants wall warning signs with symbols only, no text
P3|Cash register|1|0.4|3500|old mechanical cash register
P3|Filing tray|1|0.3|1000|metal in/out tray
P4|Telephone switchboard|1|1.0|6000|old operator switchboard with cables
P4|Wall map frame|1|1.2|1500|framed old city map, no readable text
P4|Speaker podium|1|1.1|3000|wooden speaker podium with microphone
P4|Microphone stand|1|1.5|1500|old microphone on stand
P4|Clock tower mechanism|1|2.0|10000|large clock gears mechanism, brass
P4|Staff lockers|1|2.0|6000|staff lockers with open doors
P4|Break-room table|1|1.2|3000|break room table with mugs
P4|Old coffee machine|1|0.5|3500|old drip coffee machine
"""),
("Q", "Cinema, library, community hall", "Entertainment street", """
P2|Cinema seat row|2|2.5|6000|row of 4 old red cinema seats, torn, folding
P2|Cinema screen|1|8.0|4000|large cinema screen with torn edge on stage
P2|Film projector|1|0.8|7000|old 35mm film projector on stand, reels
P2|Film reel cans|3|0.4|1500|3 variants stacked film reel cans
P2|Cinema stage curtain|1|6.0|5000|heavy red stage curtain, half open, tattered
P2|Theatre stage with footlights|1|8.0|8000|wooden theatre stage with footlights
P2|Ticket counter|1|2.0|5000|cinema ticket counter with brass grille
P3|Popcorn machine|1|1.7|7000|old popcorn machine, glass cracked
P3|Cinema poster frame|3|1.0|1200|3 variants film poster frames, no readable text, creepy toy-themed art
P3|Spotlight on stand|1|1.5|3500|theatre spotlight on stand
P3|Tall library bookshelf|2|2.5|6000|2 variants tall wooden library bookshelves
P3|Reading table|1|2.0|4000|long library reading table with green lamp
P3|Card catalogue cabinet|1|1.2|6000|library card catalogue drawers
P3|Library ladder|1|2.5|3000|rolling library ladder
P3|Book piles|3|0.4|1500|3 variants piles of old books
P3|Community hall stage|1|6.0|6000|small community hall stage
P3|Folding tables|1|1.8|2000|folding tables stacked
P3|Banquet chairs stack|1|1.2|3000|stack of banquet chairs
P3|Disco ball|1|0.5|3000|old mirror disco ball, dusty
P3|Small stage curtains|1|5.0|4000|small stage curtains
P3|Record player|1|0.5|4000|record player with vinyl
P3|Vinyl records stack|1|0.4|1500|stack of vinyl records in sleeves
P3|Piano stool|1|0.5|1500|piano stool
P3|Big speakers|2|1.0|3500|2 variants big wooden speakers
P3|Mic and stand|1|1.5|1500|mic on stand
P4|Puppet theatre stage|1|2.0|8000|small wooden puppet theatre with red curtain
P4|Children story corner|1|2.0|5000|library story corner with cushions and low shelf
P4|Chalkboard easel|1|1.4|2000|chalkboard on easel
P4|Big wall clock|1|0.8|2500|large old wall clock
P4|Lectern|1|1.1|3000|wooden lectern
P4|Torn tapestry|1|2.0|2500|torn tapestry on wall
P4|Armor stand|1|1.8|6000|decorative armor stand
P4|Theatre masks|3|0.3|1500|3 variants theatrical masks hanging
P4|Magician cabinet|1|0.8|4000|magician's cabinet box with sword slots
"""),
("W", "Bazaar: shops & market stalls", "Bazaar", """
P2|Sweet shop counter|1|3.0|6000|sweet shop counter with glass display, empty trays
P2|Sweet jars|3|0.3|1500|3 variants big glass jars with dried sweets
P2|Toy shop shelf|2|2.0|5000|2 variants shop shelf packed with toys
P2|Cloth rolls rack|1|1.2|3000|rolls of cloth on a counter rack
P2|Barber chair|1|1.0|6000|old red barber chair with footrest
P2|Barber mirror station|1|1.8|4000|barber station mirror with combs
P2|Chai stall|1|2.5|7000|roadside chai stall with kettle and glasses
P2|Chai glasses tray|1|0.3|1200|tray of small chai glasses
P3|Fruit cart|1|2.0|5000|wooden fruit cart with rotten fruit
P3|Paan kiosk|1|1.8|5000|small paan kiosk with jars
P3|Bakery rack|1|1.5|4000|bakery rack with stale bread
P3|Pharmacy shelf|1|2.0|5000|pharmacy shelves with bottles
P3|TV shop wall|1|2.5|7000|wall of old CRT televisions
P3|Shop shutter|2|3.0|2000|2 variants rolling steel shutters, half up
P3|Blank shop signboard|4|2.0|1500|4 variants hanging shop signboards, blank faded
P3|Hand pump|1|1.2|3000|old hand water pump
P3|Old weighing scale|1|0.6|3000|old balance scale with weights
P3|Vegetable baskets|3|0.5|1800|3 variants woven baskets with rotten veggies
P3|Spice sacks|3|0.7|2500|3 variants sacks of spices rolled open
P3|Old bicycle|2|1.8|6000|2 variants old bicycles, rusted
P3|Old scooter|1|1.8|10000|old scooter parked, dusty
P3|Street food cart|1|2.0|6000|street food cart with glass front
P3|Tarpaulin stall roof|1|3.0|2500|blue tarpaulin stall cover torn
P3|Hanging toy bunting|1|4.0|2000|bunting with hanging toys
P3|Tin trunk|1|0.8|2500|old painted tin trunk
P3|Rope coil|1|0.4|1000|rope coil
P3|Wooden crate stack|3|0.8|2000|3 variants stacked wooden crates
P3|Jute sacks|3|0.7|1800|3 variants jute sacks
P3|Pottery stall|1|2.0|5000|stall of clay pots
P3|Bangle rack|1|1.2|3000|rack of colored bangles
P3|Doll stall|1|2.0|6000|market stall full of dolls
P3|Mask stall|1|2.0|5000|stall of masks hanging
P3|Kite stall|1|2.0|4000|stall with kites hanging
P3|Balloon seller pole|1|2.0|2500|balloon seller pole with deflated balloons
P3|Ice-cream cart|1|1.8|5000|old ice-cream cart with umbrella
P3|Newspaper bundles|1|0.5|1200|bundles of old newspapers tied
P4|Market slab|1|2.0|3000|stone market slab, empty
P4|Hook rail|1|2.0|2500|hook rail, empty, rusty
P4|Watch repair bench|1|1.8|4000|watch repair bench with tools
P4|Shoe shop display|1|1.5|3500|shoe display shelf
P4|Tailor table with machine|1|1.5|5000|tailor table with sewing machine
P4|Roadside cabin|1|1.5|3500|small roadside cabin
P4|Hand-pulled rickshaw|1|3.0|8000|hand-pulled rickshaw
P4|Camera shop display|1|1.5|4000|old camera display with tripod
P4|Photo studio backdrop|1|3.0|3000|photo studio painted backdrop and stool
"""),
("Y", "Underground lab & sewer", "Underground", """
P2|Lab table|2|2.0|5000|steel lab table with beakers and burners
P2|Beakers and flasks|4|0.3|1500|4 variants lab glassware sets
P2|Centrifuge|1|0.6|4000|lab centrifuge machine
P2|Brain-jar specimen|2|0.5|3500|glass jar with glowing blue memory swirl inside
P2|Restraint chair|1|1.2|6000|steel chair with straps and cables, medical
P2|Server rack|2|2.0|8000|old computer server rack with blinking lights
P2|Monitor wall|1|3.0|6000|wall of old monitors with static
P2|Floor cable bundles|3|3.0|3000|3 variants thick cable bundles
P2|Specimen shelf|1|2.0|6000|shelves of glass jars containing toy parts
P3|Lab operating lamp|1|1.5|5000|overhead lab lamp
P3|Microscope|1|0.5|4000|old microscope
P3|Test tube rack|1|0.3|1500|test tube rack with colored liquids
P3|Chemical drums|3|1.0|2500|3 variants chemical drums with symbols
P3|Hazard barrel|1|0.9|2000|yellow hazard barrel
P3|Biohazard door|1|2.2|4000|heavy sealed door leaf with symbols only
P3|Airlock door|1|2.4|6000|round airlock hatch door leaf
P3|Control console|1|2.0|8000|big control console with levers and dials
P3|Glowing coil machine|1|2.5|8000|odd glowing coil machine
P3|Sewer pipe junction|2|2.0|3500|2 variants sewer pipe junction
P3|Sewer floor grate|1|1.0|1500|floor sewer grate
P3|Big sewer valve|1|1.5|3500|large sewer valve wheel
P3|Sewer ladder|1|3.0|2000|rusty sewer ladder
P3|Caged tunnel lamp|1|0.5|1500|caged tunnel lamp
P3|Drain channel piece|1|3.0|2500|stone drain channel
P3|Metal catwalk|1|3.0|4000|metal catwalk section with railing
P3|Chains pile|1|0.8|2000|pile of chains
P3|Large brass gear|3|1.0|3000|3 variants large brass gears
P3|Lab generator|1|2.0|9000|industrial lab generator
P3|Elevator shaft door|1|2.4|5000|heavy elevator door leaf
P4|Cryo glass pod|1|2.2|10000|glass cryo pod with fog
P4|Giant toy mold|1|2.0|6000|giant metal mold for toy shapes
P4|Memory tapes wall|1|2.5|5000|wall of labeled magnetic tapes, no readable text
P4|Large glass tank|1|3.0|9000|large glass tank with dim liquid
P4|Surgical tray|1|0.5|2000|surgical tray with toy-making tools
P4|Gurney with sheet|1|2.0|5000|old gurney with sheet
P4|Big vent shaft|1|2.0|3000|large ventilation shaft pipe
P4|Pressure gauge|1|0.3|1500|pressure gauge dial
P4|Emergency eyewash|1|0.8|2000|wall emergency eyewash
P4|Lab coat on hook|1|1.0|2000|lab coat hanging
P4|Pipe-organ machine|1|4.0|12000|huge strange machine of pipes and bellows
P4|Tall warped mirror|1|3.0|4000|tall warped mirror panel
P4|Stone altar|1|1.5|4000|stone altar slab with candle stubs
"""),
("U", "Lights & electrical", "All", """
P2|Wall sconce|3|0.3|1200|3 variants old wall sconces
P2|Chandelier|2|1.0|6000|2 variants dusty cracked chandeliers
P2|Oil lantern|2|0.3|2000|2 variants old lantern
P2|Candlestick|3|0.3|1000|3 variants candle holders with melted candles
P2|Bare bulb on wire|2|0.2|600|2 variants hanging bare bulbs
P2|Emergency light box|1|0.4|1500|wall emergency light box with red lamp
P2|Neon sign shapes|3|1.0|2000|3 variants glowing neon shapes (star, smile, arrow), no text
P3|Industrial spotlight|1|0.8|2500|industrial spotlight on stand
P3|Wall switchboard|3|0.3|1200|3 variants wall switchboards
P3|Wall socket|1|0.1|400|wall socket
P3|Electric meter box|1|0.5|2500|electric meter box with glass
P3|Tangled extension cable|1|0.5|800|tangled extension cable
P3|Cable tray|1|3.0|1500|wall cable tray
P3|Big transformer|1|2.5|6000|industrial transformer
P3|Insulator set|1|1.0|2000|insulator set
P3|Battery bank|1|1.0|3500|stack of car batteries
P3|Big fuse panel|1|1.5|4000|large fuse panel with many switches
P3|Warning beacon|1|0.3|1500|rotating warning beacon
P3|Loudspeaker horn|1|0.5|2000|PA loudspeaker horn
P3|Broken hanging tube light|1|1.2|1000|broken tube light hanging
"""),
("D", "Decor, clutter & atmosphere", "All", """
P2|Scattered papers|4|0.5|600|4 variants floor paper scatter, flat mesh
P2|Overturned chair|2|0.9|2500|2 variants fallen chairs
P2|Glass shards|3|0.4|700|3 variants glass shards
P2|Cobweb corner|3|0.6|600|3 variants corner cobwebs, thin
P2|Dust sheet over furniture|3|1.5|2500|3 variants white sheets over furniture
P2|Trash bag pile|3|0.8|1500|3 variants garbage bag piles
P2|Plastic bottles|3|0.3|800|3 variants empty bottles
P2|Rusty cans|3|0.2|800|3 variants rusty cans
P3|Open books on floor|3|0.4|1200|3 variants open books on floor
P3|Old shoes pair|4|0.3|1200|4 variants old shoes
P3|Clothes heap|3|0.6|1500|3 variants clothes heap
P3|Old umbrella|2|0.9|1500|2 variants old umbrellas
P3|Handbag|2|0.4|1800|2 variants handbags
P3|Old hat|2|0.3|1200|2 variants old hats
P3|Loose doll head|3|0.2|2500|3 variants loose doll heads
P3|Doll limbs pile|2|0.5|3000|2 variants piles of doll limbs
P3|Scattered marbles|1|0.3|1500|scattered glass marbles
P3|Wooden planks|3|1.5|1200|3 variants planks
P3|Brick pile|2|0.8|2000|2 variants brick piles
P3|Cement bags|2|0.6|1500|2 variants cement bags
P3|Paint cans|3|0.3|1200|3 variants paint cans with drips
P3|Bucket|2|0.4|1200|2 variants buckets
P3|Mop in bucket|1|1.2|2500|mop in bucket
P3|Metal toolbox|2|0.5|2200|2 variants metal toolboxes
P3|Wire coil|1|0.4|1000|coil of electric wire
P3|Pipe pieces|3|1.0|1200|3 variants pipe pieces
P3|Rusty wheelbarrow|1|1.2|3000|rusty wheelbarrow
P3|Barbed wire roll|1|0.8|2000|barbed wire roll
P3|Concrete chunks|4|0.6|1500|4 variants concrete chunks
P3|Shredded cloth nest|1|0.3|1500|nest of shredded cloth
P3|Hanging vines|3|2.5|2000|3 variants vines hanging, thin
P3|Moss patch|2|1.0|800|2 variants moss patches
P3|Dark puddle flat|2|1.0|400|2 variants dark puddle flat mesh
P3|Dust pile|1|0.6|500|dust pile
P3|Fallen ceiling tiles|3|1.0|1500|3 variants ceiling tile debris
P3|Broken wall hole edge|1|1.2|2000|broken wall hole edge with bricks
P3|Dripping pipe|1|1.0|1500|pipe with drip
P4|Crayon drawings|3|1.0|800|3 variants child crayon drawings on paper (scribbles, no text)
P4|Handprints plaque|1|0.5|600|wall plaque with small handprints
P4|Height marks door frame|1|2.0|1000|door frame with height pencil marks
P4|Wall stickers|1|0.3|400|old stickers on wall
P4|Torn posters|3|1.2|800|3 variants torn posters, no text
P4|Paper lanterns|3|0.4|1500|3 variants paper lanterns
P4|Party hats|3|0.2|800|3 variants party hats
P4|Used confetti cannon|1|0.3|1000|used confetti cannon
P4|Streamers|1|3.0|1000|hanging streamers
P4|Cake candles|3|0.1|400|3 variants candles
P4|Gift boxes|3|0.4|1200|3 variants wrapped gift boxes
P4|Dead leaf piles|2|1.0|600|2 variants dead leaf piles
P4|Toy capsules|3|0.1|600|3 variants plastic toy capsules
P4|Tiny kids shoes|2|0.15|900|2 variants tiny shoes
P4|Hopscotch chalk grid|2|1.5|300|2 variants hopscotch chalk grid (flat)
"""),
("P", "Puzzle items & tools", "All", """
P2|Brass gear cog|4|0.3|1500|4 variants brass gears for puzzle
P2|Puzzle box|2|0.3|3000|2 variants ornate puzzle boxes
P2|Animal statue set|4|0.6|3500|4 variants animal statues (elephant, lion, monkey, bear) for puzzle
P2|Stone pedestal|2|1.0|2000|2 variants stone pedestals
P2|Combination padlock|1|0.15|1500|combination padlock
P2|Padlock and chain|1|0.4|1500|heavy padlock and chain
P2|Crowbar|1|0.6|2000|crowbar
P2|Bolt cutters|1|0.7|2500|bolt cutters
P2|Claw hammer|1|0.35|1500|claw hammer
P2|Big wrench|1|0.4|1500|big wrench
P2|Screwdriver set|1|0.25|1500|screwdrivers
P2|Lock pick set|1|0.15|1000|lock pick set
P3|Metal whistle|1|0.1|500|metal whistle (distraction)
P3|Throwable tin can|1|0.1|500|tin can for throwing
P3|Firecracker|2|0.1|500|2 variants firecrackers
P3|Small hand bell|1|0.15|800|hand bell
P3|Music box key|1|0.1|600|winding key for music box
P3|Record disc|3|0.3|800|3 variants records for gramophone
P3|Projector reel|1|0.25|1500|film reel
P3|Colored valve handles|4|0.2|1000|4 colors valve handles (red, blue, green, yellow)
P3|Red switch lever|1|0.4|1500|red lever
P3|Symbol tokens|4|0.1|500|4 variants wooden symbol tokens
P3|Mirror shard|1|0.3|1000|mirror shard
P3|Stone tablets|3|0.5|1500|3 variants stone tablets with symbols only
P3|Rope|1|0.4|1000|rope
P3|Portable ladder|1|2.0|2500|portable ladder
P3|Plank bridge|1|2.0|1200|wooden plank
P3|Colored key cards|3|0.1|500|3 variants colored key cards
P3|Door code note|1|0.15|300|note with symbols
P3|Walkie-talkie|1|0.2|2500|walkie-talkie for story voice
P3|Polaroid photos|3|0.1|300|3 variants old polaroids
P3|Water pistol|1|0.2|1500|plastic water pistol
P3|Horseshoe magnet|1|0.1|800|horseshoe magnet
P3|Brass compass|1|0.08|800|brass compass
P3|Large medkit|1|0.35|2500|first aid kit
P3|Pill bottle|1|0.08|600|pill bottle, no text
P3|Chocolate bar|1|0.15|500|chocolate bar wrapper, no text
"""),
("V", "Vehicles", "City", """
P2|Old police car|1|4.5|18000|old police car, boxy, light bar
P2|Old fire truck|1|8.0|25000|old red fire truck with ladder
P2|Toy company delivery truck|1|7.0|22000|box delivery truck with toy mural, no text
P2|Forklift|1|3.0|12000|old forklift
P3|Kid tricycle|2|0.7|3500|2 variants kid's tricycle, rusty
P3|Baby pram|1|1.0|4000|old baby pram
P3|Go-kart|1|1.5|6000|go-kart
P3|Old city tram|1|12.0|30000|old city tram
P3|Cycle rickshaw|1|2.5|8000|cycle rickshaw
P3|Old motorcycle|1|2.0|10000|old motorcycle
P3|Old school van|1|5.0|15000|old school van
P3|Garbage truck|1|7.0|20000|old garbage truck
P3|Food truck|1|5.0|18000|old food truck
P4|Hot-air balloon basket|1|3.0|8000|hot-air balloon basket with deflated balloon
P4|Carnival train|1|6.0|14000|small carnival train
P4|Rollercoaster car|1|2.5|8000|carnival coaster car
"""),
("Z", "Extra monsters & figures", "Per mohalla", """
P2|Master-ji puppet (school)|1|2.0|30000|tall teacher puppet in old suit, long cane, chalk-dust, full body T-pose|R
P2|Nurse doll (hospital)|1|1.7|28000|faceless nurse doll with cap and syringe hand, full body T-pose|R
P2|Doctor Khilauna (hospital)|1|1.9|32000|tall doctor puppet with mask and long gloves, full body T-pose|R
P2|Maskhara jester (carnival)|1|1.8|30000|jester puppet with bells and long smile, full body T-pose|R
P2|Ringmaster (carnival)|1|2.0|32000|top-hat ringmaster puppet with whip, full body T-pose|R
P2|Giant clown head|1|3.0|35000|huge rolling clown head with mouth that opens|R
P2|Conductor puppet (metro)|1|2.0|30000|train conductor puppet with lantern and cap, full body T-pose|R
P2|Projectionist (cinema)|1|1.9|30000|thin figure with film reel head, full body T-pose|R
P3|Dukandaar doll (bazaar)|2|1.5|25000|2 variants shopkeeper dolls, apron, smile, full body T-pose|R
P3|Policeman doll|1|1.8|28000|old policeman doll with baton, full body T-pose|R
P3|Firefighter doll|1|1.8|28000|firefighter doll with helmet, full body T-pose|R
P3|Balloon smiler|1|2.0|20000|tall floating balloon figure with painted smile and strings|R
P3|Swing child doll|1|1.0|20000|child doll that sits on a swing, full body|R
P3|Large tin soldier|1|2.0|25000|large tin soldier with key, full body T-pose|R
P3|Crawler (doll-limb spider)|1|1.0|22000|spider-like creature of doll limbs and heads|R
P3|Mirror twin|1|1.8|25000|figure resembling heroine but warped, full body T-pose|R
P3|Toy rats|2|0.4|8000|2 variants toy rats, small, mechanical|R
P3|Chorus dolls (singing)|3|0.9|15000|3 variants small dolls that sing in choir, full body|R
P4|Giant puppet-string hands|1|3.0|10000|giant pair of hands holding strings from ceiling|R
P4|Shadow puppet|1|1.8|10000|flat dark puppet silhouette cut-out figure|R
"""),
("SE", "School extras", "School mohalla", """
P3|Chalk and duster|1|0.2|600|chalk box and duster
P3|Ruler and geometry box|1|0.3|700|wooden ruler and geometry box
P3|Cricket bat and ball|1|0.9|2000|old cricket bat and ball
P3|Deflated football|1|0.3|1500|deflated football
P3|Skipping rope|1|1.5|800|skipping rope
P3|School flag pole|1|5.0|2000|school flag pole, tattered flag no emblem
P3|Dormitory bed|1|2.0|5000|school dormitory bed
P3|Assembly stage|1|5.0|5000|school assembly stage platform
P3|Water tap row|1|1.0|3000|school water tap row
P3|Kids lunch boxes|3|0.2|1000|3 variants kids lunch boxes
P3|Slate board|1|0.3|800|kid's slate
P3|Abacus|1|0.3|2000|wooden abacus
P3|Classroom skeleton|1|1.7|6000|classroom skeleton
P3|Rolling blackboard|1|1.5|2500|rolling blackboard
P4|Kids paintings|3|1.0|800|3 variants kids paintings
P4|Small kids desk set|1|0.8|3000|small kids desk set
"""),
("HE", "Hospital extras", "Hospital mohalla", """
P3|Old syringes|3|0.15|600|3 variants old syringes
P3|Hospital pill bottles|3|0.1|600|3 variants pill bottles
P3|Wheelchair ramp|1|3.0|2500|metal ramp
P3|Torn hospital curtain|1|2.0|2500|torn curtain
P3|Bedside cabinet|1|0.6|2500|bedside cabinet
P3|Waiting room bench|1|2.0|3000|bench row
P3|Hospital pharmacy counter|1|2.5|5000|hospital pharmacy counter
P3|Lab sample fridge|1|1.7|5000|lab fridge
P3|Surgical gown on hook|1|1.2|1500|surgical gown on hook
P3|Bandage roll|2|0.1|600|2 variants bandage rolls
P3|Stethoscope|1|0.3|800|stethoscope
P3|Nurses station|1|3.0|7000|nurses station desk
P3|Crash cart|1|1.0|4000|medical crash cart
P4|Baby incubator|1|1.0|5000|old incubator with toys inside
P4|Old x-ray machine|1|2.0|8000|old x-ray machine
"""),
("CE", "Carnival extras", "Carnival mohalla", """
P3|Ring toss stall|1|3.0|5000|ring toss stall with bottles
P3|Balloon dart stall|1|3.0|5000|balloon dart stall
P3|Fortune teller booth|1|2.5|8000|old fortune teller booth with a mannequin
P3|Haunted house facade|1|8.0|15000|carnival ghost house facade, no text
P3|Coaster track piece|2|6.0|8000|2 variants coaster track pieces
P3|Chair swing ride|1|10.0|15000|chair-swing ride, rusty
P3|Bumper boats pool|1|6.0|7000|dry pool with boats
P3|Carnival picket fence|1|3.0|1500|colorful picket fence
P3|Carnival entry arch|1|6.0|8000|carnival entry arch with bulbs
P3|Prize plush toys|3|0.5|3000|3 variants prize plush toys
P3|Clown mask stand|1|1.5|3000|stand of clown masks
P3|Carnival lamp post|1|4.0|3000|carnival lamp post with bulbs
P4|Carousel horse single|3|1.6|7000|3 variants carousel horse
P4|Old trampoline|1|3.0|2500|old trampoline
P4|Water-gun game stall|1|2.5|5000|water-gun game stall
"""),
("RE", "Metro, roads & park extras", "Metro / City", """
P3|Ticket vending machine|1|1.8|6000|metro ticket machine
P3|Platform signs symbols|3|1.2|1500|3 variants platform signs, symbols only
P3|Metro track piece|1|6.0|3000|metro track section
P3|Train front cab|1|4.0|15000|metro train front
P3|Station pillar|1|4.0|3000|concrete pillar with tile
P3|Station bench|1|2.0|3000|bench
P3|Metro map board|1|2.0|2500|map board no text
P3|Railway signal|1|3.0|3000|railway signal
P3|Escalator side panel|1|3.0|4000|escalator side
P3|Flyover pillar|1|8.0|5000|concrete flyover pillar
P3|Bridge section|1|10.0|12000|bridge section
P3|Dark traffic light|1|5.0|3000|traffic light, dark
P3|Zebra crossing flat|1|4.0|300|flat road crossing
P3|Road barrier|2|2.0|2000|2 variants road barriers
P3|Large dumpster|1|1.8|3500|large dumpster
P3|Old signpost|1|3.0|2500|old signpost
P3|Underpass tunnel piece|1|8.0|8000|underpass tunnel section
P3|Dry garden fountain|1|3.0|8000|dry fountain with statue
P3|Broken garden statue|2|2.0|6000|2 variants broken garden statues
P3|Gazebo|1|4.0|8000|old gazebo
P3|Dirty pond|1|6.0|3000|dirty pond
P3|Huge dead tree|1|10.0|15000|huge old dead tree with twisted roots
"""),
("X", "Modular kit (OPTIONAL - main procedural bana dunga)", "All", """
P4|Wall segment plain|4|3.0|1200|OPTIONAL: plain plaster wall segment 3m, 4 variants dirty
P4|Wall with door opening|2|3.0|1500|OPTIONAL: wall with door opening
P4|Wall with window opening|2|3.0|1500|OPTIONAL: wall with window opening
P4|Floor tile piece|4|3.0|800|OPTIONAL: 4 variants floor tiles dirty checker/concrete/wood/lino
P4|Ceiling piece|3|3.0|800|OPTIONAL: ceiling panel with stains
P4|Corner piece|2|3.0|1200|OPTIONAL: wall corner
P4|Pillar|2|3.0|1500|OPTIONAL: concrete pillar
P4|Arch|2|3.0|2500|OPTIONAL: brick arch
P4|Stair module|2|3.0|3000|OPTIONAL: stair module
P4|Ramp module|1|3.0|1500|OPTIONAL: ramp module
P4|Balcony|1|3.0|3500|OPTIONAL: balcony with railing
P4|Roof piece|2|3.0|2500|OPTIONAL: tiled roof piece
P4|Skirting board|1|3.0|400|OPTIONAL: skirting board
P4|Door frame|2|2.4|1200|OPTIONAL: door frame
P4|Window frame|2|1.5|1200|OPTIONAL: window frame
P4|Broken window glass|1|1.5|600|OPTIONAL: broken glass pane
"""),
]
import sys; sys.path.insert(0, str(Path(__file__).resolve().parent))
from asset_data_extra import SECTIONS_EXTRA
SECTIONS += SECTIONS_EXTRA
NAMES = {"P1":"PEHLE BANAO (Act 1)", "P2":"DUSRE NUMBAR", "P3":"BAAD MEIN", "P4":"BONUS / BAHUT BAAD MEIN"}

old_csv = ROOT / "docs/ASSET_LIST.csv"
prev = list(csv.DictReader(open(old_csv, encoding="utf-8-sig")))
done = {r["ID"]: r.get("Done", "") for r in prev}
base = [r for r in prev if re.match(r"^[A-Z]\d{2}$", r["ID"]) and r["ID"][0] in OLD]
rows = list(base)
for code, cat, district, body in SECTIONS:
    for i, line in enumerate([l for l in body.strip().splitlines() if l.strip()], 1):
        f = line.split("|")
        rig = "RIG" if len(f) > 6 and f[6].strip() == "R" else "-"
        rows.append({"ID": f"{code}{i:02d}", "Priority": f[0], "Category": cat, "Act": district, "Name": f[1], "Variants": f[2],
                     "Size_m": f[3], "Tris_budget": f[4], "Rig_Anim": rig, "Prompt": f[5], "Done": ""})
for r in rows:
    r["Done"] = done.get(r["ID"], r.get("Done", ""))
with open(old_csv, "w", newline="", encoding="utf-8-sig") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)

STYLE = "Dark horror game asset, abandoned 1980s Indian toy-factory town, worn and dusty, realistic PBR, muted desaturated colors, single object centered, plain light-grey background, front three-quarter view, no cast shadow, high detail"
nvar = sum(int(r["Variants"]) for r in rows)
byc = {}
for r in rows: byc.setdefault(r["Category"], []).append(r)
L = ["# KHILAUNA NAGAR - SAARE 3D MODEL v2 (BADA GAME)", "",
     f"Total {len(rows)} cheezein ({nvar} models, variants milake). Pehli 40 (P1) se Act 1 chalega; baaki se poora bada shehar + har imaarat ka andar ka saman.", "",
     "Har line mein prompt poora tayyar hai (style pehle se juda hua). Seedha copy karke 3D tool mein paste karo.",
     "[RIG] = character/monster, T-pose mein banwana. 'x3' = 3 alag roop banwana. Darwaaze = sirf darwaaze ka patra. Flat/thin cheezein (papers, puddle) = patli mesh.",
     "File naam: ID_naam.glb  (jaise L01_sofa_3seater_v1.glb), ek file 15 MB se kam.",
     "Priority: P1 pehle, P2 dusre, P3 baad mein, P4 bonus. 'DONE' = mil chuka.", "",
     "## Mohalle (districts) aur andar ke kamre",
     "Factory (Act 1) | School | Hospital | Carnival/Mela | Metro & streets | Bazaar | Housing colony (ghar) | Civic (office, bank, police, fire) | Entertainment (cinema, library, hall) | Underground lab & sewer | Maa Ghar (Act 3).",
     "Har imaarat enter ho sakti hai: andar ke kamre in props se bharenge (ghar: living, bedroom, kitchen, bathroom; dukaan; cinema; hospital ward; school class; office...).", ""]
order = ["Monsters & characters", "Factory (Act 1)", "Toys (set dressing)", "Gameplay items"]
cats = [c for c in byc]
for cat in cats:
    L += ["", f"## {cat}", ""]
    for r in byc[cat]:
        v = f" x{r['Variants']}" if r["Variants"] != "1" else ""
        rig = " [RIG]" if r["Rig_Anim"] == "RIG" else ""
        dn = " (DONE)" if r["Done"] else ""
        L.append(f"- {r['ID']} | {r['Priority']} | {r['Name']}{v}{rig} | {r['Size_m']} m | max {int(r['Tris_budget'])//1000 if int(r['Tris_budget'])>=1000 else r['Tris_budget']}{'k' if int(r['Tris_budget'])>=1000 else ''} tris{dn}")
        L.append(f"  PROMPT: {STYLE}, {r['Prompt']}")
        L.append("")
(ROOT / "docs/KHILAUNA_NAGAR_ALL_3D_MODELS_v2.md").write_text("\n".join(L) + "\n", encoding="utf-8")
from collections import Counter
print("items", len(rows), "models", nvar); print(dict(Counter(r["Priority"] for r in rows)))
print("rig:", sum(1 for r in rows if r["Rig_Anim"] == "RIG"), "| done:", sum(1 for r in rows if r["Done"]))
for c, v in byc.items(): print(f"  {len(v):3} {c}")
