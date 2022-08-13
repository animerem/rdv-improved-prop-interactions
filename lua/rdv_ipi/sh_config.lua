local CAT = "Improved Prop Interact"

RDV.LIBRARY.AddConfigOption("IPI::Enabling", { 
    TYPE = RDV.LIBRARY.TYPE.BL, 
    CATEGORY = CAT,
    DESCRIPTION = "Enable or Disable this Module",
    DEFAULT = true,
    SECTION = "Main"
})

RDV.LIBRARY.AddConfigOption("IPI::MaximumDistance", { 
    TYPE = RDV.LIBRARY.TYPE.NM, 
    CATEGORY = CAT,
    DESCRIPTION = "How far away a player can be to interact with a prop",
    DEFAULT = 108,
    SECTION = "Main",
    MIN = 30,
    MAX = 2000
})

RDV.LIBRARY.AddConfigOption("IPI::MinimumDistance", { 
    TYPE = RDV.LIBRARY.TYPE.NM, 
    CATEGORY = CAT,
    DESCRIPTION = "How close by a player can be to interact with a prop",
    DEFAULT = 60,
    SECTION = "Main",
    MIN = 30,
    MAX = 2000
})

RDV.LIBRARY.AddConfigOption("IPI::AngSensitivity", { 
    TYPE = RDV.LIBRARY.TYPE.NM, 
    CATEGORY = CAT,
    DESCRIPTION = "The sensitivity of prop rotation",
    DEFAULT = 1,
    SECTION = "Main",
    MIN = 0,
    MAX = 100
})

RDV.LIBRARY.AddConfigOption("IPI::ThrowPower", { 
    TYPE = RDV.LIBRARY.TYPE.NM, 
    CATEGORY = CAT,
    DESCRIPTION = "The throwing strength for props",
    DEFAULT = 1,
    SECTION = "Main",
    MIN = 0,
    MAX = 2000
})

RDV.LIBRARY.AddConfigOption("IPI::CarryStrength", { 
    TYPE = RDV.LIBRARY.TYPE.NM, 
    CATEGORY = CAT,
    DESCRIPTION = "The carry strength for props",
    DEFAULT = 1,
    SECTION = "Main",
    MIN = 0,
    MAX = 100
})