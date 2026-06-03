// import $ from "jquery";

// export function save_data(data, data_dir, file_name) {$.ajax({
//     type: 'post',
//     cache: false,
//     url: "./exp_data/save_data.php", // save_url 
//     data: {
//       data_dir: data_dir,
//       file_name: file_name, // the file type should be added
//       exp_data: data,
//     }
//   });
// }


// TODO: test or use old version
export async function save_data(data, data_dir, file_name) {
  const saveUrl =
    (typeof import.meta !== "undefined" && import.meta.env?.VITE_SAVE_DATA_URL) ||
    "./exp_data/save_data.php";
  const experimentFolder =
    (typeof import.meta !== "undefined" && import.meta.env?.VITE_EXPERIMENT_FOLDER) ||
    "";

  const response = await fetch(saveUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      data_dir: data_dir,
      experiment_folder: experimentFolder,
      file_name: file_name,
      exp_data: data,
    }),
  });

  return response.text();
}
