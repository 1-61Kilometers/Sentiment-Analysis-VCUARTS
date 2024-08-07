using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class CSVWriter : MonoBehaviour
{
    private static string filename = "";
    

    void Start()
    {
        // Set the file path
        filename = Application.persistentDataPath;
        setUpFile();
        Debug.Log("CSV FILE PATH: " + filename + "emotion_data.csv");
        Debug.Log("PERSISTENT DATA PATH:" + Application.persistentDataPath);
    }
    private void Update()
    {
        Debug.Log("PERSISTENT DATA PATH:" + Application.persistentDataPath);
    }
    private static void setUpFile()
    {
        //using (StreamWriter outputFile = new StreamWriter(Path.Combine(filename, "emotion_data.csv")))
        //{
            //outputFile.WriteLine("BrowLowererL,BrowLowererR,CheekPuffL,CheekPuffR,CheekRaiserL,CheekRaiserR,CheekSuckL,CheekSuckR,ChinRaiserB,ChinRaiserT,DimplerL,DimplerR,EyesClosedL,EyesClosedR,EyesLookDownL,EyesLookDownR,EyesLookLeftL,EyesLookLeftR,EyesLookRightL,EyesLookRightR,EyesLookUpL,EyesLookUpR,InnerBrowRaiserL,InnerBrowRaiserR,JawDrop,JawSidewaysLeft,JawSidewaysRight,JawThrust,LidTightenerL,LidTightenerR,LipCornerDepressorL,LipCornerDepressorR,LipCornerPullerL,LipCornerPullerR,LipFunnelerLB,LipFunnelerLT,LipFunnelerRB,LipFunnelerRT,LipPressorL,LipPressorR,LipPuckerL,LipPuckerR,LipsToward,LipStretcherL,LipStretcherR,LipSuckLB,LipSuckLT,LipSuckRB,LipSuckRT,LipTightenerL,LipTightenerR,LowerLipDepressorL,LowerLipDepressorR,MouthLeft,MouthRight,NoseWrinklerL,NoseWrinklerR,OuterBrowRaiserL,OuterBrowRaiserR,UpperLidRaiserL,UpperLidRaiserR,UpperLipRaiserL,UpperLipRaiserR,emotion");
            //outputFile.Close();
        //}
            
    }

    public static void AddData(string[] data)
    {
        try
        {
            using(StreamWriter outputFile = new StreamWriter(Path.Combine(filename, "emotion_data.csv")))
            {
                if (data.Length > 0)
                {
                    try
                    {
                        outputFile.WriteLine(string.Join(",", data));
                        File.AppendAllLines(filename,data);
                        outputFile.Close();
                    }
                    catch (Exception e)
                    {
                        Debug.LogError("Error in the WriteLine Code: "+e.Message);
                    }
                }
                else
                {
                    Debug.Log("Trying to write to csv file but data is empty");
                    outputFile.Close();
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogError("Error writing to CSV file - " + filename +"emotion_data.csv" +" error message : " + e.Message);
        }
       

        
    }

    

}
