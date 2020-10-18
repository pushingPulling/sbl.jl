using sbl

using HTTP
using JSON3
using DataFrames

function download_json(cid, record_type="3d")
    pc_uri = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/JSON?record_type=$record_type"

    HTTP.request("GET", pc_uri).body
end

function read_json(filename)
    pb_json_txt = ""

    open(filename, "r") do pb_json_f
        pb_json_txt = read(pb_json_f, String)
    end

    pb_json_txt
end

pb_json_txt = read_json("sbl/test/data/aspirin_pug.json");

r = JSON3.read(pb_json_txt, PCResult)

# pb_json = JSON.parse(String(pb_json_response.body))

# for (i, compound) in enumerate(pb_json["PC_Compounds"])

# end


# pb_json = jsontable(String(pb_json_response.body))

# pb_df = DataFrame(pb_json)

# print(pb_df)