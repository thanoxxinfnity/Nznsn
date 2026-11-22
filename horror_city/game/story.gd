class_name Story
extends RefCounted
# Kahani ka text (English; Hindi Tr.HI se).

static func item_name(id: String) -> String:
	match id:
		"key_hall": return Tr.t("Reception key")
		"fuse": return Tr.t("Ceramic fuse")
		"diary1": return Tr.t("Diary 1")
		"diary2": return Tr.t("Diary 2")
		"diary3": return Tr.t("Diary 3")
		"letter": return Tr.t("Mother's letter")
	return id

static func letter_t() -> String:
	return Tr.t("Mother's last letter")

static func letter() -> String:
	return Tr.t("Neha, my child,\n\nIf you are reading this, I never made it back. I left the doll down there, beneath the factory. Never bring her out.\n\nAnd child… don't take my doll downstairs.\n\n— Maa")

static func d1_t() -> String:
	return Tr.t("Savitri's diary — page 1")

static func d1() -> String:
	return Tr.t("The machines ran late again today. The owners say Rangeela Toys' dolls must look 'alive'. We painters have to put something of ourselves into every doll's eyes.\n\nFrom tomorrow everyone is on night shift. The front gate stays locked from the inside now.")

static func d2_t() -> String:
	return Tr.t("Savitri's diary — page 2")

static func d2() -> String:
	return Tr.t("The engine is eating our memories.\n\nRamu no longer remembers his own name. My daughter's face is blurring in my mind. The dolls move at night — just not while anyone is watching them.\n\nKeep the light on them. Light stops them.")

static func d3_t() -> String:
	return Tr.t("Savitri's diary — page 3")

static func d3() -> String:
	return Tr.t("The fuse box is in the generator room, but I hid the fuse in the paint room. Whoever starts the lift will wake the whole engine.\n\nIf you come, run, Neha. Don't look back.")

static func start_sub() -> String:
	return Tr.t("Neha: Maa… I made it. This is the factory.")

static func obj_enter() -> String:
	return Tr.t("Go inside the factory")

static func obj_key() -> String:
	return Tr.t("Find the key in reception")

static func obj_hall() -> String:
	return Tr.t("Cross the assembly hall — keep your eyes on the doll")

static func obj_fuse() -> String:
	return Tr.t("Find the fuse in the paint room")

static func obj_gen() -> String:
	return Tr.t("Put the fuse in the generator room")

static func obj_lift() -> String:
	return Tr.t("Run to the lift!")

static func end_t() -> String:
	return Tr.t("Chapter 1 complete")

static func end_b() -> String:
	return Tr.t("The lift keeps sinking…\n\nSomewhere in the dark, a lullaby plays in your mother's voice.\n\nNext: Chapter 2 — the four neighbourhoods of Khilauna Nagar.")
