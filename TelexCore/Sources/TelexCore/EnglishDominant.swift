// EnglishDominant.swift — SINH TỰ ĐỘNG bởi `gen-english --frequency`, ĐỪNG SỬA TAY.
// Từ tiếng Anh mà Telex gõ ra âm tiết Việt hợp lệ, nhưng tiếng Anh phổ biến hơn
// ít nhất 1 bậc độ lớn và từ Việt đó hiếm (dưới 10 điểm). Khôi phục về
// tiếng Anh ngay cả khi "Ưu tiên tiếng Việt". Tần suất: FrequencyWords (Hermit Dave,
// OpenSubtitles 2018, CC BY-SA 4.0). Cách sinh lại: GenEnglish/Frequency.swift.
enum EnglishDominant {
    /// Sorted ascii, lowercase. 432 từ, tra Set ở boundary (không trên hot path).
    static let words: Set<String> = {
        var set = Set<String>(minimumCapacity: 432)
        for token in list.split(whereSeparator: { $0 == " " || $0 == "\n" }) {
            set.insert(String(token))
        }
        return set
    }()

    private static let list = """
        afar ajar arm asa ask aux baa bama
        barks bask basra bern best bias bier boar
        boars boast boats boers boom booms bora bore
        bores born bosom boxer boxers boxes bums bur
        burn burns bury busy buys cary casa cask
        caw caws ceos ceres cern chairs chaps charm
        charms chasm cheer chest chief chiefs choir chore
        chores chose chosen chums churn coast coats coax
        coons cops core cores corps corset cost darn
        dawn deems defuse dens denser deserts died dies
        dir dire doer does dojo donor donors doom
        door doors dora dorado dorms dosa dose dosed
        dost dots down downs dust dvd exes gangs
        ganja gee gees gene genes genre genres germ
        gets ghost gifts gist goats goes goons gore
        gown gowns gums guns guts guys haas hangar
        harm harps haw hawks her here hero herpes
        hex hips hire hires hoax hoes honor honors
        hoops horn horns horse hose hums ire isa
        isn kana kara karma keen keeps kern kora
        koran kris kronor larks law laws liar liars
        lies life lifer lips lira lire list loans
        lora lore loren lose loser major mama mamas
        manga mans maps mara marks mask meets mere
        mins minx mire miser mixer mixers mixes moans
        moms mora moray more mores morn moron morons
        morse moser most mums must nana narcs nasa
        naw nieces nips nix norm norms norse nose
        nuns oar oats oops ops or ore oren
        orson oxen pairs pangs pans par para parks
        parm parma parts pas past pasta pats paw
        pawn pawns paws pays pecs pee peeps peer
        peers pees pens per perjure perm perps peruse
        peso pest pets photos pieces pier pierces piers
        pies pins pips pits pix poems poets poof
        poofs poor pops pore pores porn porno pornos
        ports pos pose poser post pots pow pows
        pox puja puns pups puree puri pus puts
        quarks quasar queens queer queue queues quips raj
        raja raw rawr refers refuse reps rest rife
        rims rips rise riser roams roar roars roast
        roofs rooms roos rosa rosary rose saran saw
        saws says seem seems seer sees sense serf
        sexes sims sins sire sirs sis sits sixes
        soaps soars sofa sofas sons soon sore sores
        sox sums surf sux sworn tara task taxi
        teens tens tense term terms test tex thats
        themes thief thorn thorns those tier tiers ties
        tire tires tongs tons tops tore torn town
        towns traps trays trees tres trier tries trips
        trojan trojans troops turn turns tux twas urn
        urns vasa vern vips vise war wars wax
        woo woof worm worms worn wrong wrongs xerox
        zaps zero zeros zest zips zits zoom zoos
        """
}
