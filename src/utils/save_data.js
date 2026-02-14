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
  const response = await fetch("./exp_data/save_data.php", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      data_dir: data_dir,
      file_name: file_name,
      exp_data: data,
    }),
  });

  return response.text();
}
